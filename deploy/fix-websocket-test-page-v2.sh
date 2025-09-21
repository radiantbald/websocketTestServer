#!/bin/bash

# Исправление тестовой страницы WebSocket (версия 2)
# Более радикальный подход к исправлению проблемы со скачиванием файла

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

log "🔧 Исправление тестовой страницы WebSocket (версия 2)..."

# Создаем резервную копию
BACKUP_FILE="$NGINX_CONFIG.backup.$(date +%Y%m%d-%H%M%S)"
sudo cp "$NGINX_CONFIG" "$BACKUP_FILE"
log "📦 Резервная копия создана: $BACKUP_FILE"

# Проверяем, что файл существует
if [ ! -f "$PROJECT_DIR/client/test-client.html" ]; then
    error "❌ Файл test-client.html не найден: $PROJECT_DIR/client/test-client.html"
    exit 1
fi

log "✅ Файл test-client.html найден"

# Полностью переписываем блок websocket-test
log "📝 Полная перезапись блока /websocket-test..."

# Создаем временный файл с исправленной конфигурацией
TEMP_FILE=$(mktemp)

# Копируем конфигурацию до блока websocket-test
sudo sed '/location \/websocket-test {/,/}/d' "$NGINX_CONFIG" > "$TEMP_FILE"

# Добавляем исправленный блок websocket-test перед закрывающей скобкой server
sed -i '$d' "$TEMP_FILE"  # Удаляем последнюю закрывающую скобку

cat >> "$TEMP_FILE" << 'EOF'
    
    # WebSocket тестовая страница
    location = /websocket-test {
        root /var/www/qabase/client;
        index test-client.html;
        try_files $uri /test-client.html;
        add_header Content-Type "text/html; charset=utf-8";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
    
    # Альтернативный способ через proxy
    location /websocket-test-proxy {
        proxy_pass http://127.0.0.1:9092;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Заменяем оригинальный файл
sudo cp "$TEMP_FILE" "$NGINX_CONFIG"
rm "$TEMP_FILE"

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

# Тест основного пути
TEST_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://qabase.ru/websocket-test 2>/dev/null || echo "000")
CONTENT_TYPE=$(curl -s -I https://qabase.ru/websocket-test 2>/dev/null | grep -i "content-type" || echo "")

echo "  📊 /websocket-test - HTTP $TEST_STATUS"
echo "  📄 Content-Type: $CONTENT_TYPE"

# Тест альтернативного пути
TEST_PROXY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://qabase.ru/websocket-test-proxy 2>/dev/null || echo "000")
echo "  📊 /websocket-test-proxy - HTTP $TEST_PROXY_STATUS"

# Проверяем, что файл доступен напрямую
if [ -f "$PROJECT_DIR/client/test-client.html" ]; then
    FILE_SIZE=$(ls -lh "$PROJECT_DIR/client/test-client.html" | awk '{print $5}')
    echo "  📁 Размер файла: $FILE_SIZE"
fi

if [ "$TEST_STATUS" = "200" ] && [[ "$CONTENT_TYPE" == *"text/html"* ]]; then
    log "✅ Тестовая страница теперь отображается как HTML!"
elif [ "$TEST_PROXY_STATUS" = "200" ]; then
    log "✅ Альтернативный путь работает!"
    log "🌐 Используйте: https://qabase.ru/websocket-test-proxy"
else
    warning "⚠️  Проблема может остаться. Попробуйте:"
    echo "  🌐 https://qabase.ru/websocket-test"
    echo "  🌐 https://qabase.ru/websocket-test-proxy"
    echo "  🔧 Проверьте права доступа к файлу"
fi

log "🎉 Исправление завершено!"
log "🌐 Тестовая страница: https://qabase.ru/websocket-test"
log "🌐 Альтернативный путь: https://qabase.ru/websocket-test-proxy"
log "🔌 WebSocket endpoint: wss://qabase.ru/websocket"
