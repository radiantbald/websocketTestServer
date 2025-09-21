#!/bin/bash

# Скрипт для быстрого исправления проблем с systemd сервисом
# Использование: ./fix-service.sh

set -e

PROJECT_DIR="/var/www/qabase"
SERVICE_NAME="websocket-server"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

log "🔧 Исправляем проблемы с сервисом $SERVICE_NAME..."

# Проверяем, что мы в правильной директории
if [ ! -d "$PROJECT_DIR" ]; then
    error "Директория проекта не найдена: $PROJECT_DIR"
fi

cd $PROJECT_DIR

# Останавливаем сервис
log "⏹️  Останавливаем сервис..."
sudo systemctl stop $SERVICE_NAME || warning "Сервис не был запущен"

# Убиваем все процессы websocket-server
log "🔄 Завершаем все процессы websocket-server..."
sudo pkill -f websocket-server || warning "Процессы не найдены"

# Ждем завершения процессов
sleep 2

# Проверяем, что порт свободен
if sudo netstat -tlnp | grep -q ":9092"; then
    warning "⚠️  Порт 9092 все еще занят, принудительно освобождаем..."
    sudo fuser -k 9092/tcp || true
    sleep 2
fi

# Обновляем конфигурацию сервиса
log "📄 Обновляем конфигурацию сервиса..."
sudo cp $PROJECT_DIR/deploy/websocket-server.service /etc/systemd/system/

# Перезагружаем systemd
log "🔄 Перезагружаем systemd daemon..."
sudo systemctl daemon-reload

# Проверяем права на бинарный файл
log "🔐 Проверяем права на бинарный файл..."
if [ -f "$PROJECT_DIR/server/websocket-server" ]; then
    sudo chown www-data:www-data $PROJECT_DIR/server/websocket-server
    sudo chmod +x $PROJECT_DIR/server/websocket-server
    log "✅ Права на бинарный файл обновлены"
else
    error "❌ Бинарный файл не найден: $PROJECT_DIR/server/websocket-server"
fi

# Включаем автозапуск
log "✅ Включаем автозапуск сервиса..."
sudo systemctl enable $SERVICE_NAME

# Запускаем сервис
log "▶️  Запускаем сервис..."
sudo systemctl start $SERVICE_NAME

# Ждем запуска
sleep 3

# Проверяем статус
log "🔍 Проверяем статус сервиса..."
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    log "✅ Сервис $SERVICE_NAME успешно запущен!"
    sudo systemctl status $SERVICE_NAME --no-pager
else
    warning "⚠️  Сервис не запустился, показываем диагностику..."
    sudo systemctl status $SERVICE_NAME --no-pager
    log "📋 Последние логи:"
    sudo journalctl -u $SERVICE_NAME -n 10 --no-pager
    error "❌ Не удалось запустить сервис. Проверьте логи выше."
fi

log "🎉 Исправление завершено!"
