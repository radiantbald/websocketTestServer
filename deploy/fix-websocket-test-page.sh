#!/bin/bash

# Исправление тестовой страницы WebSocket
# Исправляет проблему со скачиванием файла вместо отображения HTML

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

log "🔧 Исправление тестовой страницы WebSocket..."

# Создаем резервную копию
BACKUP_FILE="$NGINX_CONFIG.backup.$(date +%Y%m%d-%H%M%S)"
sudo cp "$NGINX_CONFIG" "$BACKUP_FILE"
log "📦 Резервная копия создана: $BACKUP_FILE"

# Исправляем конфигурацию websocket-test
log "📝 Исправление конфигурации /websocket-test..."
sudo sed -i '/location \/websocket-test {/,/}/c\
    # WebSocket тестовая страница\
    location /websocket-test {\
        root /var/www/qabase/client;\
        try_files /test-client.html =404;\
        add_header Content-Type text/html;\
    }' "$NGINX_CONFIG"

# Проверяем синтаксис
log "🔍 Проверка синтаксиса nginx..."
if sudo nginx -t; then
    log "✅ Синтаксис корректен"
    sudo systemctl reload nginx
    log "✅ Nginx перезагружен"
else
    error "❌ Ошибка в синтаксисе!"
    log "🔄 Восстанавливаем резервную копию..."
    sudo cp "$BACKUP_FILE" "$NGINX_CONFIG"
    exit 1
fi

# Тестируем исправление
log "🧪 Тестирование исправления..."
TEST_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://qabase.ru/websocket-test 2>/dev/null || echo "000")
CONTENT_TYPE=$(curl -s -I https://qabase.ru/websocket-test 2>/dev/null | grep -i "content-type" || echo "")

echo "  📊 HTTP статус: $TEST_STATUS"
echo "  📄 Content-Type: $CONTENT_TYPE"

if [ "$TEST_STATUS" = "200" ] && [[ "$CONTENT_TYPE" == *"text/html"* ]]; then
    log "✅ Тестовая страница теперь отображается как HTML!"
else
    warning "⚠️  Проблема может остаться. Проверьте вручную:"
    echo "  🌐 Откройте: https://qabase.ru/websocket-test"
fi

log "🎉 Исправление завершено!"
log "🌐 Тестовая страница: https://qabase.ru/websocket-test"
log "🔌 WebSocket endpoint: wss://qabase.ru/websocket"
