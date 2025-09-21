#!/bin/bash

# Скрипт настройки systemd сервиса для WebSocket сервера
# Использование: ./setup-service.sh

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
    echo "Настройка systemd сервиса для WebSocket сервера"
    echo ""
    echo "Использование: $0 [опции]"
    echo ""
    echo "Опции:"
    echo "  --remove    - Удалить сервис"
    echo "  --status    - Показать статус сервиса"
    echo "  --restart   - Перезапустить сервис"
    echo "  --help      - Показать эту справку"
    echo ""
    echo "Примеры:"
    echo "  $0              # Создать/обновить сервис"
    echo "  $0 --status     # Показать статус"
    echo "  $0 --restart    # Перезапустить"
    echo "  $0 --remove     # Удалить сервис"
}

# Параметры
REMOVE=false
STATUS_ONLY=false
RESTART_ONLY=false

# Обработка параметров
while [[ $# -gt 0 ]]; do
    case $1 in
        --remove)
            REMOVE=true
            shift
            ;;
        --status)
            STATUS_ONLY=true
            shift
            ;;
        --restart)
            RESTART_ONLY=true
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

# Показать статус
if [ "$STATUS_ONLY" = true ]; then
    log "📊 Статус сервиса $SERVICE_NAME:"
    echo ""
    sudo systemctl status $SERVICE_NAME --no-pager || warning "Сервис не найден"
    exit 0
fi

# Перезапустить сервис
if [ "$RESTART_ONLY" = true ]; then
    log "🔄 Перезапускаем сервис $SERVICE_NAME..."
    sudo systemctl restart $SERVICE_NAME
    sleep 2
    sudo systemctl status $SERVICE_NAME --no-pager
    exit 0
fi

# Удалить сервис
if [ "$REMOVE" = true ]; then
    log "🗑️  Удаляем сервис $SERVICE_NAME..."
    
    # Останавливаем сервис
    sudo systemctl stop $SERVICE_NAME || warning "Сервис не запущен"
    
    # Отключаем автозапуск
    sudo systemctl disable $SERVICE_NAME || warning "Сервис не был включен"
    
    # Удаляем файл сервиса
    sudo rm -f /etc/systemd/system/$SERVICE_NAME.service
    
    # Перезагружаем systemd
    sudo systemctl daemon-reload
    
    log "✅ Сервис $SERVICE_NAME удален"
    exit 0
fi

# Создаем/обновляем сервис
log "🔧 Настраиваем systemd сервис для WebSocket сервера..."

# Проверяем, существует ли бинарный файл
if [ ! -f "$PROJECT_DIR/server/websocket-server" ]; then
    error "Бинарный файл websocket-server не найден. Сначала соберите проект."
fi

# Останавливаем существующий сервис
if sudo systemctl list-unit-files | grep -q "$SERVICE_NAME.service"; then
    log "⏹️  Останавливаем существующий сервис..."
    sudo systemctl stop $SERVICE_NAME || warning "Не удалось остановить сервис"
fi

# Копируем файл сервиса
log "📋 Копируем конфигурацию сервиса..."
sudo cp $PROJECT_DIR/deploy/websocket-server.service /etc/systemd/system/

# Перезагружаем systemd
log "🔄 Перезагружаем systemd..."
sudo systemctl daemon-reload

# Включаем автозапуск
log "🔗 Включаем автозапуск..."
sudo systemctl enable $SERVICE_NAME

# Запускаем сервис
log "▶️  Запускаем сервис..."
sudo systemctl start $SERVICE_NAME

# Проверяем статус
log "🔍 Проверяем статус..."
sleep 3

if sudo systemctl is-active --quiet $SERVICE_NAME; then
    log "✅ Сервис $SERVICE_NAME успешно запущен"
else
    error "❌ Ошибка при запуске сервиса $SERVICE_NAME"
fi

# Показываем статус
log "📊 Статус сервиса:"
sudo systemctl status $SERVICE_NAME --no-pager

log "🎉 Настройка сервиса завершена!"
log "📋 Полезные команды:"
echo "  sudo systemctl status $SERVICE_NAME    # Статус сервиса"
echo "  sudo systemctl restart $SERVICE_NAME   # Перезапуск"
echo "  sudo systemctl stop $SERVICE_NAME      # Остановка"
echo "  sudo systemctl start $SERVICE_NAME     # Запуск"
echo "  sudo journalctl -u $SERVICE_NAME -f    # Логи"
