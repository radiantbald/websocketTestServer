#!/bin/bash

# Настройка правильной маршрутизации WebSocket
# Настраивает /websocket для тестовой страницы и /websocket-api для WebSocket API

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

NGINX_CONFIG="/etc/nginx/sites-available/qabase.ru"
PROJECT_DIR="/var/www/qabase"

log "🔧 Настройка правильной маршрутизации WebSocket..."

# Создаем резервную копию
BACKUP_FILE="$NGINX_CONFIG.backup.$(date +%Y%m%d-%H%M%S)"
sudo cp "$NGINX_CONFIG" "$BACKUP_FILE"
log "📦 Резервная копия создана: $BACKUP_FILE"

# Получаем путь к директории скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Копируем обновленную конфигурацию
log "📝 Копирование обновленной nginx конфигурации..."
sudo cp "$SCRIPT_DIR/nginx-qabase-clean.conf" "$NGINX_CONFIG"

# Проверяем синтаксис
log "🔍 Проверка синтаксиса nginx..."
if sudo nginx -t; then
    log "✅ Синтаксис nginx корректен"
    sudo systemctl reload nginx
    log "✅ Nginx перезагружен"
else
    error "❌ Ошибка в синтаксисе nginx!"
    log "🔄 Восстанавливаем резервную копию..."
    sudo cp "$BACKUP_FILE" "$NGINX_CONFIG"
    exit 1
fi

# Пересобираем и перезапускаем WebSocket сервер
log "🔨 Пересборка WebSocket сервера..."
cd "$PROJECT_DIR"
if [ -f "Makefile" ]; then
    make build
else
    cd server
    go mod tidy
    go build -o websocket-server main.go
    cd ..
fi

# Устанавливаем права
sudo chown www-data:www-data server/websocket-server
sudo chmod +x server/websocket-server

# Перезапускаем сервис
log "🔄 Перезапуск WebSocket сервера..."
sudo systemctl restart websocket-server

# Ждем запуска
sleep 3

# Проверяем статус
if sudo systemctl is-active --quiet websocket-server; then
    log "✅ WebSocket сервер запущен"
else
    error "❌ WebSocket сервер не запустился"
    exit 1
fi

# Тестируем endpoints
log "🧪 Тестирование endpoints..."

# Тест /websocket (должен отдавать HTML страницу)
WEBSOCKET_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://qabase.ru/websocket 2>/dev/null || echo "000")
echo "  📊 /websocket (HTML страница) - HTTP $WEBSOCKET_STATUS"

# Тест /api/websocket (должен отклонять HTTP запросы)
WEBSOCKET_API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://qabase.ru/api/websocket 2>/dev/null || echo "000")
echo "  📊 /api/websocket (WebSocket API) - HTTP $WEBSOCKET_API_STATUS"

# Тест /status
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://qabase.ru/status 2>/dev/null || echo "000")
echo "  📊 /status - HTTP $STATUS_CODE"

# Проверяем результаты
if [ "$WEBSOCKET_STATUS" = "200" ]; then
    log "✅ /websocket отдает HTML страницу"
else
    warning "⚠️  /websocket вернул код: $WEBSOCKET_STATUS"
fi

if [ "$WEBSOCKET_API_STATUS" = "400" ]; then
    log "✅ /api/websocket правильно отклоняет HTTP запросы"
else
    warning "⚠️  /api/websocket вернул код: $WEBSOCKET_API_STATUS"
fi

if [ "$STATUS_CODE" = "200" ]; then
    log "✅ /status работает"
else
    warning "⚠️  /status вернул код: $STATUS_CODE"
fi

echo ""
log "🎉 Настройка маршрутизации WebSocket завершена!"
log "🌐 Тестовая страница: https://qabase.ru/websocket"
log "🔌 WebSocket API: wss://qabase.ru/api/websocket"
log "📊 Статус: https://qabase.ru/status"

echo ""
log "📋 Как использовать:"
echo "  1. Откройте https://qabase.ru/websocket в браузере"
echo "  2. Введите имя пользователя"
echo "  3. Нажмите 'Подключиться'"
echo "  4. JavaScript подключится к wss://qabase.ru/api/websocket"
echo "  5. Отправляйте сообщения в чат"

echo ""
log "📋 Полезные команды:"
echo "  sudo systemctl status websocket-server    # Статус сервера"
echo "  sudo journalctl -u websocket-server -f    # Логи сервера"
echo "  curl https://qabase.ru/status             # Проверка API"
