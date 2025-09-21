#!/bin/bash

# Быстрое обновление WebSocket сервера на qabase.ru
# Использование: ./quick-update.sh

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

# Проверяем, что мы на сервере
if [ ! -d "$PROJECT_DIR" ]; then
    error "❌ Директория $PROJECT_DIR не найдена. Убедитесь, что вы находитесь на сервере qabase.ru"
fi

log "🚀 Начинаем быстрое обновление WebSocket сервера..."

# Переходим в директорию проекта
cd $PROJECT_DIR

# Останавливаем сервис
log "⏹️  Останавливаем WebSocket сервер..."
sudo systemctl stop $SERVICE_NAME || warning "Сервис уже остановлен"

# Обновляем код из GitHub
log "📥 Обновляем код из GitHub..."
git fetch origin
git pull origin main

# Пересобираем приложение
log "🔨 Пересобираем приложение..."
cd $PROJECT_DIR/server
go mod tidy
go build -o websocket-server main.go

# Устанавливаем права
sudo chown www-data:www-data websocket-server
sudo chmod +x websocket-server

# Запускаем сервис
log "▶️  Запускаем WebSocket сервер..."
sudo systemctl start $SERVICE_NAME

# Проверяем статус
log "🔍 Проверяем статус сервиса..."
sleep 2
sudo systemctl status $SERVICE_NAME --no-pager -l

# Тестируем соединение
log "🧪 Тестируем соединение..."
sleep 3
if curl -f -s https://qabase.ru/status > /dev/null; then
    log "✅ Сервер успешно обновлен и работает!"
    log "🌐 Статус: https://qabase.ru/status"
    log "🔌 WebSocket: wss://qabase.ru/websocket"
else
    error "❌ Сервер не отвечает после обновления"
fi

log "🎉 Обновление завершено успешно!"
