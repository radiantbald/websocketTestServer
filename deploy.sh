#!/bin/bash

# WebSocket Test Server - Единый скрипт развертывания
# Использование: ./deploy.sh [опции]

set -e

# Переменные
PROJECT_DIR="/var/www/qabase"
SERVICE_NAME="websocket-server"
NGINX_CONFIG="/etc/nginx/sites-available/qabase.ru"
NGINX_ENABLED="/etc/nginx/sites-enabled/qabase.ru"

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
    echo "WebSocket Test Server - Единый скрипт развертывания"
    echo ""
    echo "Использование: $0 [опции]"
    echo ""
    echo "Опции:"
    echo "  --full-deploy    - Полное развертывание (код + nginx + ssl + сервис)"
    echo "  --update-only    - Только обновление кода и перезапуск сервиса"
    echo "  --nginx-only     - Только настройка nginx"
    echo "  --ssl-only       - Только настройка SSL"
    echo "  --service-only   - Только настройка systemd сервиса"
    echo "  --status         - Показать статус всех компонентов"
    echo "  --logs           - Показать логи сервиса"
    echo "  --restart        - Перезапустить сервис"
    echo "  --help           - Показать эту справку"
    echo ""
    echo "Примеры:"
    echo "  $0 --full-deploy    # Полное развертывание"
    echo "  $0 --update-only    # Быстрое обновление"
    echo "  $0 --status         # Проверить статус"
}

# Проверка прав
check_permissions() {
    if [ "$EUID" -ne 0 ]; then
        error "Этот скрипт должен запускаться с правами root (sudo)"
    fi
}

# Проверка зависимостей
check_dependencies() {
    log "🔍 Проверяем зависимости..."
    
    # Проверяем Go
    if ! command -v go &> /dev/null; then
        warning "Go не установлен. Устанавливаем..."
        wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
        tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
        export PATH=$PATH:/usr/local/go/bin
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
        rm -f go1.21.5.linux-amd64.tar.gz
        log "✅ Go установлен"
    else
        log "✅ Go уже установлен"
    fi
    
    # Проверяем nginx
    if ! command -v nginx &> /dev/null; then
        warning "Nginx не установлен. Устанавливаем..."
        apt update
        apt install -y nginx
        log "✅ Nginx установлен"
    else
        log "✅ Nginx уже установлен"
    fi
    
    # Проверяем certbot
    if ! command -v certbot &> /dev/null; then
        warning "Certbot не установлен. Устанавливаем..."
        apt install -y certbot python3-certbot-nginx
        log "✅ Certbot установлен"
    else
        log "✅ Certbot уже установлен"
    fi
}

# Создание директории проекта
setup_project_dir() {
    log "📁 Настраиваем директорию проекта..."
    
    if [ ! -d "$PROJECT_DIR" ]; then
        mkdir -p "$PROJECT_DIR"
        log "✅ Директория $PROJECT_DIR создана"
    fi
    
    cd "$PROJECT_DIR"
    
    # Клонируем репозиторий если его нет
    if [ ! -d ".git" ]; then
        log "📥 Клонируем репозиторий..."
        git clone https://github.com/radiantbald/websocketTestServer.git .
        log "✅ Репозиторий клонирован"
    fi
    
    # Устанавливаем права
    chown -R www-data:www-data "$PROJECT_DIR"
    chmod +x "$PROJECT_DIR/deploy"/*.sh
    log "✅ Права установлены"
}

# Обновление кода
update_code() {
    log "📥 Обновляем код из GitHub..."
    
    cd "$PROJECT_DIR"
    
    # Сохраняем локальные изменения
    git stash push -m "Auto-update $(date +'%Y-%m-%d %H:%M:%S')" || info "Нет локальных изменений"
    
    # Обновляем код
    git fetch origin
    git pull origin main
    
    # Восстанавливаем локальные изменения
    git stash pop || info "Нет сохраненных изменений"
    
    log "✅ Код обновлен"
}

# Сборка приложения
build_application() {
    log "🔨 Собираем приложение..."
    
    cd "$PROJECT_DIR/server"
    
    # Обновляем зависимости
    go mod tidy
    go mod download
    
    # Собираем приложение
    go build -o websocket-server main.go
    
    # Устанавливаем права
    chown www-data:www-data websocket-server
    chmod +x websocket-server
    
    log "✅ Приложение собрано"
}

# Настройка systemd сервиса
setup_service() {
    log "⚙️  Настраиваем systemd сервис..."
    
    # Копируем конфигурацию сервиса
    cp "$PROJECT_DIR/deploy/websocket-server.service" /etc/systemd/system/
    
    # Перезагружаем systemd
    systemctl daemon-reload
    
    # Включаем автозапуск
    systemctl enable "$SERVICE_NAME"
    
    log "✅ Systemd сервис настроен"
}

# Настройка nginx
setup_nginx() {
    log "🌐 Настраиваем nginx..."
    
    # Удаляем дефолтную конфигурацию
    rm -f /etc/nginx/sites-enabled/default
    
    # Копируем конфигурацию
    cp "$PROJECT_DIR/deploy/nginx-qabase.conf" "$NGINX_CONFIG"
    
    # Создаем символическую ссылку
    ln -sf "$NGINX_CONFIG" "$NGINX_ENABLED"
    
    # Проверяем конфигурацию
    nginx -t
    
    log "✅ Nginx настроен"
}

# Настройка SSL
setup_ssl() {
    log "🔒 Настраиваем SSL сертификаты..."
    
    # Получаем SSL сертификат
    certbot --nginx -d qabase.ru -d www.qabase.ru --non-interactive --agree-tos --email admin@qabase.ru
    
    # Настраиваем автообновление
    systemctl enable certbot.timer
    systemctl start certbot.timer
    
    log "✅ SSL настроен"
}

# Запуск сервисов
start_services() {
    log "▶️  Запускаем сервисы..."
    
    # Запускаем WebSocket сервер
    systemctl start "$SERVICE_NAME"
    
    # Перезапускаем nginx
    systemctl restart nginx
    
    log "✅ Сервисы запущены"
}

# Проверка статуса
check_status() {
    log "🔍 Проверяем статус компонентов..."
    
    echo ""
    echo "=== WebSocket Server ==="
    systemctl status "$SERVICE_NAME" --no-pager -l || warning "Сервис не запущен"
    
    echo ""
    echo "=== Nginx ==="
    systemctl status nginx --no-pager -l || warning "Nginx не запущен"
    
    echo ""
    echo "=== SSL Certificates ==="
    certbot certificates || warning "SSL сертификаты не настроены"
    
    echo ""
    echo "=== WebSocket Connection Test ==="
    if curl -f -s https://qabase.ru/status > /dev/null; then
        log "✅ WebSocket сервер отвечает"
    else
        warning "❌ WebSocket сервер не отвечает"
    fi
}

# Показать логи
show_logs() {
    log "📋 Показываем логи WebSocket сервера..."
    journalctl -u "$SERVICE_NAME" -f
}

# Перезапуск сервиса
restart_service() {
    log "🔄 Перезапускаем WebSocket сервер..."
    systemctl restart "$SERVICE_NAME"
    log "✅ Сервис перезапущен"
}

# Полное развертывание
full_deploy() {
    log "🚀 Начинаем полное развертывание..."
    
    check_permissions
    check_dependencies
    setup_project_dir
    update_code
    build_application
    setup_service
    setup_nginx
    setup_ssl
    start_services
    
    log "🎉 Полное развертывание завершено!"
    log "🌐 Сайт доступен: https://qabase.ru"
    log "🔌 WebSocket: wss://qabase.ru/websocket"
}

# Только обновление
update_only() {
    log "🔄 Обновляем только код и сервис..."
    
    check_permissions
    update_code
    build_application
    restart_service
    
    log "✅ Обновление завершено!"
}

# Только nginx
nginx_only() {
    log "🌐 Настраиваем только nginx..."
    
    check_permissions
    setup_nginx
    systemctl restart nginx
    
    log "✅ Nginx настроен!"
}

# Только SSL
ssl_only() {
    log "🔒 Настраиваем только SSL..."
    
    check_permissions
    setup_ssl
    
    log "✅ SSL настроен!"
}

# Только сервис
service_only() {
    log "⚙️  Настраиваем только systemd сервис..."
    
    check_permissions
    setup_service
    restart_service
    
    log "✅ Systemd сервис настроен!"
}

# Основная логика
main() {
    case "${1:-}" in
        --full-deploy)
            full_deploy
            ;;
        --update-only)
            update_only
            ;;
        --nginx-only)
            nginx_only
            ;;
        --ssl-only)
            ssl_only
            ;;
        --service-only)
            service_only
            ;;
        --status)
            check_status
            ;;
        --logs)
            show_logs
            ;;
        --restart)
            restart_service
            ;;
        --help)
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            error "Неизвестная опция: $1. Используйте --help для справки."
            ;;
    esac
}

# Запуск
main "$@"
