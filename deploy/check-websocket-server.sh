#!/bin/bash

# Проверка состояния WebSocket сервера
# Диагностирует проблемы с WebSocket сервером

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

info() {
    echo -e "\033[0;34m[$(date +'%H:%M:%S')] INFO: $1\033[0m"
}

SERVICE_NAME="websocket-server"
PROJECT_DIR="/var/www/qabase"

log "🔍 Проверка состояния WebSocket сервера..."

echo ""
info "📊 Статус systemd сервиса:"
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    echo "  ✅ Сервис $SERVICE_NAME активен"
else
    echo "  ❌ Сервис $SERVICE_NAME неактивен"
fi

if sudo systemctl is-enabled --quiet $SERVICE_NAME; then
    echo "  ✅ Сервис $SERVICE_NAME включен для автозапуска"
else
    echo "  ❌ Сервис $SERVICE_NAME не включен для автозапуска"
fi

echo ""
info "🔌 Проверка порта 9092:"
if netstat -tlnp 2>/dev/null | grep -q ":9092 "; then
    echo "  ✅ Порт 9092 прослушивается"
    netstat -tlnp 2>/dev/null | grep ":9092 " | sed 's/^/    /'
else
    echo "  ❌ Порт 9092 не прослушивается"
fi

echo ""
info "🌐 Тестирование локального подключения:"
# Тест HTTP статуса
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9092/status 2>/dev/null || echo "000")
echo "  📊 HTTP статус (localhost:9092/status): $HTTP_STATUS"

if [ "$HTTP_STATUS" = "200" ]; then
    echo "  ✅ WebSocket сервер отвечает на HTTP запросы"
else
    echo "  ❌ WebSocket сервер не отвечает на HTTP запросы"
fi

# Тест WebSocket endpoint
WS_HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9092/websocket 2>/dev/null || echo "000")
echo "  📊 WebSocket endpoint (localhost:9092/websocket): $WS_HTTP_STATUS"

echo ""
info "📋 Последние логи сервиса:"
echo "  📄 Последние 10 строк логов:"
sudo journalctl -u $SERVICE_NAME --no-pager -n 10 | sed 's/^/    /'

echo ""
info "🔍 Проверка файлов проекта:"
if [ -d "$PROJECT_DIR" ]; then
    echo "  ✅ Директория проекта существует: $PROJECT_DIR"
    
    if [ -f "$PROJECT_DIR/server/websocket-server" ]; then
        echo "  ✅ Исполняемый файл сервера существует"
        echo "  📊 Размер файла: $(ls -lh $PROJECT_DIR/server/websocket-server | awk '{print $5}')"
    else
        echo "  ❌ Исполняемый файл сервера не найден"
    fi
    
    if [ -f "$PROJECT_DIR/server/main.go" ]; then
        echo "  ✅ Исходный код Go существует"
    else
        echo "  ❌ Исходный код Go не найден"
    fi
else
    echo "  ❌ Директория проекта не найдена: $PROJECT_DIR"
fi

echo ""
info "🔧 Рекомендации по исправлению:"

if ! sudo systemctl is-active --quiet $SERVICE_NAME; then
    echo "  🚀 Запустить сервис: sudo systemctl start $SERVICE_NAME"
fi

if ! sudo systemctl is-enabled --quiet $SERVICE_NAME; then
    echo "  🔄 Включить автозапуск: sudo systemctl enable $SERVICE_NAME"
fi

if [ "$HTTP_STATUS" != "200" ]; then
    echo "  🔄 Перезапустить сервис: sudo systemctl restart $SERVICE_NAME"
    echo "  📋 Проверить логи: sudo journalctl -u $SERVICE_NAME -f"
fi

if [ ! -f "$PROJECT_DIR/server/websocket-server" ]; then
    echo "  🔨 Пересобрать сервер: cd $PROJECT_DIR && make build"
fi

echo ""
log "🎯 Проверка WebSocket сервера завершена!"
