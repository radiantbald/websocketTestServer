#!/bin/bash

# Скрипт управления WebSocket сервером
# Использование: ./manage.sh [start|stop|restart|status|logs|update]

set -e

SERVICE_NAME="websocket-server"
PROJECT_DIR="/var/www/qabase"

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
    echo "Управление WebSocket сервером для qabase.ru"
    echo ""
    echo "Использование: $0 [команда]"
    echo ""
    echo "Команды:"
    echo "  start     - Запустить сервер"
    echo "  stop      - Остановить сервер"
    echo "  restart   - Перезапустить сервер"
    echo "  status    - Показать статус сервера"
    echo "  logs      - Показать логи сервера"
    echo "  update    - Обновить код и перезапустить"
    echo "  test      - Протестировать соединение"
    echo "  backup    - Создать резервную копию"
    echo "  help      - Показать эту справку"
}

start_server() {
    log "Запускаем WebSocket сервер..."
    sudo systemctl start $SERVICE_NAME
    sleep 2
    if sudo systemctl is-active --quiet $SERVICE_NAME; then
        log "✅ Сервер успешно запущен"
    else
        error "❌ Ошибка запуска сервера"
    fi
}

stop_server() {
    log "Останавливаем WebSocket сервер..."
    sudo systemctl stop $SERVICE_NAME
    log "✅ Сервер остановлен"
}

restart_server() {
    log "Перезапускаем WebSocket сервер..."
    sudo systemctl restart $SERVICE_NAME
    sleep 2
    if sudo systemctl is-active --quiet $SERVICE_NAME; then
        log "✅ Сервер успешно перезапущен"
    else
        error "❌ Ошибка перезапуска сервера"
    fi
}

show_status() {
    log "Статус WebSocket сервера:"
    echo ""
    sudo systemctl status $SERVICE_NAME --no-pager
    echo ""
    
    log "Проверка доступности:"
    if curl -f -s http://localhost:9092/status > /dev/null; then
        log "✅ Сервер отвечает на localhost:9092"
    else
        warning "⚠️  Сервер не отвечает на localhost:9092"
    fi
    
    if curl -f -s https://qabase.ru/status > /dev/null; then
        log "✅ Сервер отвечает на https://qabase.ru"
    else
        warning "⚠️  Сервер не отвечает на https://qabase.ru"
    fi
}

show_logs() {
    log "Логи WebSocket сервера (последние 50 строк):"
    echo ""
    sudo journalctl -u $SERVICE_NAME -n 50 --no-pager
    echo ""
    log "Для просмотра логов в реальном времени используйте: sudo journalctl -u $SERVICE_NAME -f"
}

update_server() {
    log "Обновляем WebSocket сервер..."
    
    # Останавливаем сервер
    sudo systemctl stop $SERVICE_NAME
    
    # Обновляем код (предполагаем, что код уже скопирован)
    cd $PROJECT_DIR/server
    sudo -u www-data go mod tidy
    sudo -u www-data go build -o websocket-server main.go
    
    # Запускаем сервер
    sudo systemctl start $SERVICE_NAME
    
    sleep 2
    if sudo systemctl is-active --quiet $SERVICE_NAME; then
        log "✅ Сервер успешно обновлен и запущен"
    else
        error "❌ Ошибка обновления сервера"
    fi
}

test_connection() {
    log "Тестируем соединение с WebSocket сервером..."
    
    # Тест HTTP endpoints
    echo ""
    info "Тестируем HTTP endpoints:"
    
    if curl -f -s http://localhost:9092/status | grep -q "running"; then
        log "✅ /status endpoint работает"
    else
        warning "⚠️  /status endpoint не работает"
    fi
    
    if curl -f -s https://qabase.ru/status | grep -q "running"; then
        log "✅ HTTPS /status endpoint работает"
    else
        warning "⚠️  HTTPS /status endpoint не работает"
    fi
    
    # Тест WebSocket (базовый)
    echo ""
    info "Тестируем WebSocket соединение:"
    
    # Простой тест с wscat (если установлен)
    if command -v wscat &> /dev/null; then
        timeout 5 wscat -c ws://localhost:9092/ws?username=test 2>/dev/null && log "✅ WebSocket соединение работает" || warning "⚠️  WebSocket соединение не работает"
    else
        info "Установите wscat для тестирования WebSocket: npm install -g wscat"
    fi
}

create_backup() {
    log "Создаем резервную копию..."
    
    BACKUP_DIR="/var/backups/qabase"
    BACKUP_FILE="qabase-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    sudo mkdir -p $BACKUP_DIR
    
    sudo tar -czf $BACKUP_DIR/$BACKUP_FILE \
        -C /var/www qabase \
        -C /etc/nginx/sites-available qabase.ru \
        -C /etc/systemd/system websocket-server.service 2>/dev/null || true
    
    log "✅ Резервная копия создана: $BACKUP_DIR/$BACKUP_FILE"
}

# Основная логика
case "${1:-help}" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        restart_server
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    update)
        update_server
        ;;
    test)
        test_connection
        ;;
    backup)
        create_backup
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Неизвестная команда: $1. Используйте '$0 help' для справки."
        ;;
esac
