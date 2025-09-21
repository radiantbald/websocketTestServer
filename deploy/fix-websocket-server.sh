#!/bin/bash

# Исправление WebSocket сервера
# Пересобирает и перезапускает сервер

set -e

log() {
    echo -e "\033[0;32m[$(date +'%H:%M:%S')] $1\033[0m"
}

error() {
    echo -e "\033[0;31m[$(date +'%H:%M:%S')] ERROR: $1\033[0m"
}

warning() {
    echo -e "\033[0;33m[$(date +'%H:%M:%S')] WARNING: $1\033[0m"
}

SERVICE_NAME="websocket-server"
PROJECT_DIR="/var/www/qabase"

log "🔧 Исправление WebSocket сервера..."

# Проверяем, что мы в правильной директории
if [ ! -d "$PROJECT_DIR" ]; then
    error "❌ Директория проекта не найдена: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

# Останавливаем сервис
log "⏹️  Остановка WebSocket сервера..."
sudo systemctl stop $SERVICE_NAME

# Пересобираем сервер
log "🔨 Пересборка WebSocket сервера..."
if [ -f "Makefile" ]; then
    make build
else
    # Если нет Makefile, собираем вручную
    cd server
    go mod tidy
    go build -o websocket-server main.go
    cd ..
fi

# Проверяем, что файл создался
if [ ! -f "server/websocket-server" ]; then
    error "❌ Не удалось собрать WebSocket сервер"
    exit 1
fi

log "✅ WebSocket сервер пересобран"

# Устанавливаем правильные права
sudo chown www-data:www-data server/websocket-server
sudo chmod +x server/websocket-server

# Запускаем сервис
log "▶️  Запуск WebSocket сервера..."
sudo systemctl start $SERVICE_NAME

# Ждем немного
sleep 2

# Проверяем статус
log "📊 Проверка статуса сервиса..."
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    log "✅ WebSocket сервер запущен"
else
    error "❌ WebSocket сервер не запустился"
    log "📋 Логи сервиса:"
    sudo journalctl -u $SERVICE_NAME --no-pager -n 20
    exit 1
fi

# Тестируем endpoints
log "🔌 Тестирование endpoints..."

# Тест статуса
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9092/status 2>/dev/null || echo "000")
if [ "$HTTP_STATUS" = "200" ]; then
    log "✅ Статус endpoint работает (HTTP $HTTP_STATUS)"
else
    warning "⚠️  Статус endpoint вернул код: $HTTP_STATUS"
fi

# Тест WebSocket endpoint
WS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9092/websocket 2>/dev/null || echo "000")
if [ "$WS_STATUS" = "400" ]; then
    log "✅ WebSocket endpoint правильно отклоняет HTTP запросы (HTTP $WS_STATUS)"
else
    warning "⚠️  WebSocket endpoint вернул код: $WS_STATUS"
fi

# Тест через nginx
log "🌐 Тестирование через nginx..."
NGINX_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://qabase.ru/status 2>/dev/null || echo "000")
if [ "$NGINX_STATUS" = "200" ]; then
    log "✅ Nginx проксирует статус endpoint (HTTP $NGINX_STATUS)"
else
    warning "⚠️  Nginx статус endpoint вернул код: $NGINX_STATUS"
fi

NGINX_WS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://qabase.ru/websocket 2>/dev/null || echo "000")
if [ "$NGINX_WS_STATUS" = "400" ]; then
    log "✅ Nginx WebSocket endpoint правильно отклоняет HTTP запросы (HTTP $NGINX_WS_STATUS)"
else
    warning "⚠️  Nginx WebSocket endpoint вернул код: $NGINX_WS_STATUS"
fi

echo ""
log "🎉 Исправление WebSocket сервера завершено!"
log "🌐 Сайт: https://qabase.ru"
log "🔌 WebSocket: wss://qabase.ru/websocket"
log "📊 Статус: https://qabase.ru/status"

echo ""
log "📋 Полезные команды:"
echo "  sudo systemctl status $SERVICE_NAME    # Статус сервиса"
echo "  sudo journalctl -u $SERVICE_NAME -f    # Логи сервиса"
echo "  curl http://localhost:9092/status      # Тест локально"
