#!/bin/bash

# Быстрое исправление nginx конфигурации
# Удаляет дублирующиеся location блоки

set -e

log() {
    echo -e "\033[0;32m[$(date +'%H:%M:%S')] $1\033[0m"
}

error() {
    echo -e "\033[0;31m[$(date +'%H:%M:%S')] ERROR: $1\033[0m"
}

NGINX_CONFIG="/etc/nginx/sites-available/qabase.ru"

log "🔧 Быстрое исправление nginx конфигурации..."

# Создаем резервную копию
sudo cp "$NGINX_CONFIG" "$NGINX_CONFIG.backup.$(date +%Y%m%d-%H%M%S)"

# Удаляем дублирующиеся location /websocket блоки
log "🗑️  Удаление дублирующихся блоков..."
sudo sed -i '/location \/websocket {/,/}/d' "$NGINX_CONFIG"

# Находим место для вставки (перед закрывающей скобкой server блока)
log "📝 Добавление правильного WebSocket блока..."
# Создаем временный файл с правильным содержимым
TEMP_FILE=$(mktemp)

# Копируем содержимое до последней закрывающей скобки
sudo sed '$d' "$NGINX_CONFIG" > "$TEMP_FILE"

# Добавляем WebSocket блоки
cat >> "$TEMP_FILE" << 'EOF'
    
    # WebSocket проксирование
    location /websocket {
        # Проверяем, что это WebSocket запрос
        if ($http_upgrade != "websocket") {
            return 400;
        }
        
        proxy_pass http://127.0.0.1:9092;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket специфичные настройки
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
        proxy_connect_timeout 60;
        
        # Буферизация
        proxy_buffering off;
        proxy_cache off;
    }
    
    # WebSocket тестовая страница
    location /websocket-test {
        alias /var/www/qabase/client/test-client.html;
        try_files $uri =404;
    }
}
EOF

# Заменяем оригинальный файл
sudo cp "$TEMP_FILE" "$NGINX_CONFIG"
rm "$TEMP_FILE"

# Проверяем синтаксис
log "🔍 Проверка синтаксиса..."
if sudo nginx -t; then
    log "✅ Синтаксис корректен"
    sudo systemctl reload nginx
    log "✅ Nginx перезагружен"
else
    error "❌ Ошибка в синтаксисе!"
    exit 1
fi

log "🎉 Исправление завершено!"
