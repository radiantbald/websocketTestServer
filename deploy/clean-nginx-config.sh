#!/bin/bash

# Скрипт для полной очистки и исправления nginx конфигурации
# Устраняет дублирующиеся location блоки

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для логирования
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Переменные
NGINX_SITE="qabase.ru"
NGINX_CONFIG="/etc/nginx/sites-available/$NGINX_SITE"
NGINX_ENABLED="/etc/nginx/sites-enabled/$NGINX_SITE"
BACKUP_DIR="/etc/nginx/backup-$(date +%Y%m%d-%H%M%S)"

log "🧹 Полная очистка nginx конфигурации..."

# Создаем резервную копию
log "📦 Создание резервной копии..."
sudo mkdir -p "$BACKUP_DIR"
if [ -f "$NGINX_CONFIG" ]; then
    sudo cp "$NGINX_CONFIG" "$BACKUP_DIR/nginx.conf.backup"
    log "✅ Резервная копия создана: $BACKUP_DIR"
else
    warning "⚠️  Файл конфигурации не найден: $NGINX_CONFIG"
fi

# Получаем путь к директории скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Проверяем наличие исправленной конфигурации
if [ ! -f "$SCRIPT_DIR/nginx-qabase-clean.conf" ]; then
    error "❌ Файл nginx-qabase-clean.conf не найден в $SCRIPT_DIR"
    exit 1
fi

# Останавливаем nginx
log "⏹️  Остановка nginx..."
sudo systemctl stop nginx

# Удаляем старую конфигурацию
log "🗑️  Удаление старой конфигурации..."
sudo rm -f "$NGINX_CONFIG"
sudo rm -f "$NGINX_ENABLED"

# Копируем чистую конфигурацию
log "📝 Копирование чистой конфигурации..."
sudo cp "$SCRIPT_DIR/nginx-qabase-clean.conf" "$NGINX_CONFIG"

# Создаем символическую ссылку
log "🔗 Создание символической ссылки..."
sudo ln -sf "$NGINX_CONFIG" "$NGINX_ENABLED"

# Проверяем синтаксис
log "🔍 Проверка синтаксиса nginx..."
if sudo nginx -t; then
    log "✅ Синтаксис nginx корректен"
else
    error "❌ Ошибка в синтаксисе nginx!"
    log "🔄 Восстанавливаем резервную копию..."
    if [ -f "$BACKUP_DIR/nginx.conf.backup" ]; then
        sudo cp "$BACKUP_DIR/nginx.conf.backup" "$NGINX_CONFIG"
        sudo ln -sf "$NGINX_CONFIG" "$NGINX_ENABLED"
    fi
    exit 1
fi

# Запускаем nginx
log "▶️  Запуск nginx..."
sudo systemctl start nginx

# Проверяем статус
log "📊 Проверка статуса nginx..."
if sudo systemctl is-active --quiet nginx; then
    log "✅ Nginx запущен и работает"
else
    error "❌ Nginx не запустился!"
    exit 1
fi

# Тестируем endpoints
log "🔌 Тестирование WebSocket endpoint..."
WS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$NGINX_SITE/websocket || echo "000")
log "📊 WebSocket статус: $WS_STATUS"

if [ "$WS_STATUS" = "400" ]; then
    log "✅ WebSocket endpoint правильно отклоняет HTTP запросы (ожидаемо)"
elif [ "$WS_STATUS" = "101" ]; then
    log "✅ WebSocket endpoint работает"
else
    warning "⚠️  WebSocket endpoint вернул статус: $WS_STATUS"
fi

# Тестируем статус endpoint
log "📊 Тестирование статус endpoint..."
STATUS_RESPONSE=$(curl -s https://$NGINX_SITE/status | head -c 100)
if [[ "$STATUS_RESPONSE" == *"running"* ]]; then
    log "✅ Статус endpoint работает"
else
    warning "⚠️  Статус endpoint может не работать"
fi

# Тестируем тестовую страницу
log "🧪 Тестирование тестовой страницы..."
TEST_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$NGINX_SITE/websocket-test || echo "000")
log "📊 Тестовая страница статус: $TEST_STATUS"

if [ "$TEST_STATUS" = "200" ]; then
    log "✅ Тестовая страница доступна"
else
    warning "⚠️  Тестовая страница вернула статус: $TEST_STATUS"
fi

echo ""
log "🎉 Полная очистка nginx конфигурации завершена!"
log "🌐 Сайт доступен: https://$NGINX_SITE"
log "🔌 WebSocket endpoint: wss://$NGINX_SITE/websocket"
log "📊 Статус: https://$NGINX_SITE/status"
log "🧪 Тестовая страница: https://$NGINX_SITE/websocket-test"

echo ""
log "📋 Полезные команды:"
echo "  sudo nginx -t                    # Проверка синтаксиса"
echo "  sudo systemctl status nginx      # Статус nginx"
echo "  sudo tail -f /var/log/nginx/$NGINX_SITE.error.log  # Логи ошибок"
echo "  sudo tail -f /var/log/nginx/$NGINX_SITE.access.log # Логи доступа"
