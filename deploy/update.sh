#!/bin/bash

# Скрипт автоматического обновления WebSocket сервера
# Использование: ./update.sh

set -e

PROJECT_DIR="/var/www/qabase"
SERVICE_NAME="websocket-server"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

show_help() {
    echo "Обновление WebSocket сервера для qabase.ru"
    echo ""
    echo "Использование: $0 [опции]"
    echo ""
    echo "Опции:"
    echo "  --backup-only    - Создать только резервную копию"
    echo "  --no-backup      - Обновить без создания резервной копии"
    echo "  --force          - Принудительное обновление (игнорировать ошибки)"
    echo "  --help           - Показать эту справку"
    echo ""
    echo "Примеры:"
    echo "  $0                # Обычное обновление с резервной копией"
    echo "  $0 --no-backup    # Быстрое обновление без резервной копии"
    echo "  $0 --backup-only  # Только резервная копия"
}

# Параметры
BACKUP_ONLY=false
NO_BACKUP=false
FORCE=false

# Обработка параметров
while [[ $# -gt 0 ]]; do
    case $1 in
        --backup-only)
            BACKUP_ONLY=true
            shift
            ;;
        --no-backup)
            NO_BACKUP=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            error "Неизвестный параметр: $1. Используйте --help для справки."
            ;;
    esac
done

# Проверяем, что мы в правильной директории
if [ ! -d "$PROJECT_DIR" ]; then
    error "Директория проекта не найдена: $PROJECT_DIR"
fi

cd $PROJECT_DIR

log "🚀 Начинаем обновление WebSocket сервера..."

# Создаем резервную копию (если не отключено)
if [ "$NO_BACKUP" = false ]; then
    log "📦 Создаем резервную копию..."
    if [ -f "./deploy/manage.sh" ]; then
        ./deploy/manage.sh backup
    else
        warning "Скрипт manage.sh не найден, создаем резервную копию вручную..."
        BACKUP_DIR="/var/backups/qabase"
        BACKUP_FILE="qabase-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
        sudo mkdir -p $BACKUP_DIR
        sudo tar -czf $BACKUP_DIR/$BACKUP_FILE \
            -C /var/www qabase \
            -C /etc/nginx/sites-available qabase.ru \
            -C /etc/systemd/system websocket-server.service 2>/dev/null || true
        log "✅ Резервная копия создана: $BACKUP_DIR/$BACKUP_FILE"
    fi
fi

# Если только резервная копия
if [ "$BACKUP_ONLY" = true ]; then
    log "✅ Резервная копия создана. Обновление пропущено."
    exit 0
fi

# Останавливаем сервисы
log "⏹️  Останавливаем сервисы..."

# Проверяем, существует ли сервис
if sudo systemctl list-unit-files | grep -q "$SERVICE_NAME.service"; then
    sudo systemctl stop $SERVICE_NAME || warning "Не удалось остановить $SERVICE_NAME"
else
    warning "⚠️  Сервис $SERVICE_NAME не найден, пропускаем остановку"
fi

# Сохраняем локальные изменения
log "💾 Сохраняем локальные изменения..."
git stash push -m "Auto-update $(date +'%Y-%m-%d %H:%M:%S')" || info "Нет локальных изменений для сохранения"

# Обновляем код
log "📥 Обновляем код из GitHub..."
git fetch origin

# Проверяем, есть ли обновления
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    log "✅ Код уже актуален, обновление не требуется"
    git stash pop || true
    sudo systemctl start $SERVICE_NAME
    exit 0
fi

log "📋 Найдены обновления:"
git log --oneline $LOCAL..$REMOTE

# Получаем обновления
git pull origin main

# Восстанавливаем локальные изменения
git stash pop || info "Нет сохраненных изменений для восстановления"

# Пересобираем приложение
log "🔨 Пересобираем приложение..."
cd $PROJECT_DIR/server

# Проверяем версию Go
GO_VERSION=$(go version | grep -o 'go[0-9]\+\.[0-9]\+' | sed 's/go//')
REQUIRED_VERSION="1.21"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    warning "⚠️  Версия Go $GO_VERSION устарела. Требуется $REQUIRED_VERSION+"
    log "🔄 Обновляем Go до версии 1.21.5..."
    
    # Обновляем Go
    wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile
    
    # Проверяем обновление
    NEW_VERSION=$(go version | grep -o 'go[0-9]\+\.[0-9]\+' | sed 's/go//')
    log "✅ Go обновлен до версии $NEW_VERSION"
    
    # Очищаем временные файлы
    rm -f go1.21.5.linux-amd64.tar.gz
fi

# Обновляем зависимости
log "📦 Обновляем зависимости..."
go mod tidy
go mod download

# Собираем приложение
log "🔨 Собираем приложение..."
go build -o websocket-server main.go

# Устанавливаем права
sudo chown www-data:www-data websocket-server
sudo chmod +x websocket-server

# Обновляем конфигурации
log "⚙️  Обновляем конфигурации..."

# Systemd service
if [ -f "$PROJECT_DIR/deploy/websocket-server.service" ]; then
    sudo cp $PROJECT_DIR/deploy/websocket-server.service /etc/systemd/system/
    sudo systemctl daemon-reload
    log "✅ Systemd service обновлен"
fi

# Nginx конфигурация
if [ -f "$PROJECT_DIR/deploy/nginx-qabase.conf" ]; then
    sudo cp $PROJECT_DIR/deploy/nginx-qabase.conf /etc/nginx/sites-available/qabase.ru
    
    # Проверяем конфигурацию nginx
    if sudo nginx -t; then
        log "✅ Nginx конфигурация обновлена"
    else
        error "❌ Ошибка в конфигурации nginx"
    fi
fi

# Запускаем сервисы
log "▶️  Запускаем сервисы..."

# Проверяем и запускаем WebSocket сервер
if sudo systemctl list-unit-files | grep -q "$SERVICE_NAME.service"; then
    sudo systemctl start $SERVICE_NAME
    log "✅ WebSocket сервер запущен"
else
    warning "⚠️  Сервис $SERVICE_NAME не найден, создаем его..."
    
    # Создаем сервис
    sudo cp $PROJECT_DIR/deploy/websocket-server.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable $SERVICE_NAME
    sudo systemctl start $SERVICE_NAME
    log "✅ WebSocket сервер создан и запущен"
fi

# Перезагружаем nginx
sudo systemctl reload nginx

# Проверяем статус
log "🔍 Проверяем статус..."
sleep 3

if sudo systemctl is-active --quiet $SERVICE_NAME; then
    log "✅ WebSocket сервер запущен"
else
    error "❌ Ошибка при запуске WebSocket сервера"
fi

if sudo systemctl is-active --quiet nginx; then
    log "✅ Nginx запущен"
else
    warning "⚠️  Nginx не запущен"
fi

# Тестируем соединение
log "🧪 Тестируем соединение..."
sleep 2

if curl -f -s http://localhost:9092/status > /dev/null; then
    log "✅ Локальное соединение работает"
else
    warning "⚠️  Локальное соединение не работает"
fi

if curl -f -s https://qabase.ru/status > /dev/null; then
    log "✅ HTTPS соединение работает"
else
    warning "⚠️  HTTPS соединение не работает"
fi

# Показываем информацию об обновлении
log "📊 Информация об обновлении:"
echo "  Версия до обновления: $LOCAL"
echo "  Версия после обновления: $REMOTE"
echo "  Время обновления: $(date)"
echo "  Статус сервисов:"
sudo systemctl is-active $SERVICE_NAME && echo "    ✅ WebSocket сервер: активен" || echo "    ❌ WebSocket сервер: неактивен"
sudo systemctl is-active nginx && echo "    ✅ Nginx: активен" || echo "    ❌ Nginx: неактивен"

# Исправляем nginx конфигурацию для WebSocket
log "🔧 Исправление nginx конфигурации для WebSocket..."
NGINX_CONFIG="/etc/nginx/sites-available/qabase.ru"
if [ -f "$NGINX_CONFIG" ]; then
    # Создаем резервную копию
    BACKUP_DIR="/etc/nginx/backup-$(date +%Y%m%d-%H%M%S)"
    sudo mkdir -p "$BACKUP_DIR"
    sudo cp "$NGINX_CONFIG" "$BACKUP_DIR/nginx.conf.backup"
    
    # Копируем исправленную конфигурацию
    sudo cp "$PROJECT_DIR/deploy/nginx-qabase.conf" "$NGINX_CONFIG"
    
    # Проверяем синтаксис и перезагружаем
    if sudo nginx -t; then
        sudo systemctl reload nginx
        log "✅ Nginx конфигурация исправлена и перезагружена"
    else
        log "❌ Ошибка в nginx конфигурации, восстанавливаем резервную копию"
        sudo cp "$BACKUP_DIR/nginx.conf.backup" "$NGINX_CONFIG"
    fi
else
    warning "⚠️  Nginx конфигурация не найдена: $NGINX_CONFIG"
fi

log "🎉 Обновление завершено успешно!"
log "🌐 Сайт доступен: https://qabase.ru"
log "🔌 WebSocket: wss://qabase.ru/websocket"
log "📊 Статус: https://qabase.ru/status"

echo ""
log "Полезные команды:"
echo "  sudo systemctl status $SERVICE_NAME    # Статус сервера"
echo "  sudo journalctl -u $SERVICE_NAME -f    # Логи сервера"
echo "  ./deploy/manage.sh status              # Полная диагностика"
echo "  ./deploy/manage.sh test                # Тестирование"
