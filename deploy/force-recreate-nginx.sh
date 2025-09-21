#!/bin/bash

# Принудительное пересоздание nginx конфигурации
# Полностью удаляет старую конфигурацию и создает новую

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

NGINX_SITE="qabase.ru"
NGINX_CONFIG="/etc/nginx/sites-available/$NGINX_SITE"
NGINX_ENABLED="/etc/nginx/sites-enabled/$NGINX_SITE"
BACKUP_DIR="/etc/nginx/backup-$(date +%Y%m%d-%H%M%S)"

log "🔥 Принудительное пересоздание nginx конфигурации..."

# Создаем резервную копию
log "📦 Создание резервной копии..."
sudo mkdir -p "$BACKUP_DIR"
if [ -f "$NGINX_CONFIG" ]; then
    sudo cp "$NGINX_CONFIG" "$BACKUP_DIR/nginx.conf.backup"
    log "✅ Резервная копия создана: $BACKUP_DIR"
fi

# Получаем путь к директории скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Останавливаем nginx
log "⏹️  Остановка nginx..."
sudo systemctl stop nginx

# Полностью удаляем старую конфигурацию
log "🗑️  Удаление старой конфигурации..."
sudo rm -f "$NGINX_CONFIG"
sudo rm -f "$NGINX_ENABLED"

# Создаем новую конфигурацию с нуля
log "📝 Создание новой конфигурации..."
sudo tee "$NGINX_CONFIG" > /dev/null << 'EOF'
# Nginx конфигурация для qabase.ru WebSocket сервера
# Автоматически создана скриптом force-recreate-nginx.sh

server {
    listen 80;
    server_name qabase.ru www.qabase.ru;
    
    # Редирект на HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name qabase.ru www.qabase.ru;
    
    # SSL сертификаты
    ssl_certificate /etc/letsencrypt/live/qabase.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/qabase.ru/privkey.pem;
    
    # SSL настройки
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Заголовки безопасности
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options DENY always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Логирование
    access_log /var/log/nginx/qabase.ru.access.log;
    error_log /var/log/nginx/qabase.ru.error.log;
    
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
    
    # Статус endpoint
    location /status {
        proxy_pass http://127.0.0.1:9092;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # WebSocket тестовая страница
    location /websocket-test {
        alias /var/www/qabase/client/test-client.html;
        try_files $uri =404;
    }
    
    # Главная страница
    location = / {
        root /var/www/qabase/client;
        index index.html;
        try_files $uri /index.html;
    }
    
    # Статические файлы клиента
    location / {
        root /var/www/qabase/client;
        try_files $uri $uri/ =404;
        
        # Кэширование статических файлов
        location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Ограничения
    client_max_body_size 1M;
    client_body_timeout 60s;
    client_header_timeout 60s;
}
EOF

# Создаем символическую ссылку
log "🔗 Создание символической ссылки..."
sudo ln -sf "$NGINX_CONFIG" "$NGINX_ENABLED"

# Проверяем синтаксис
log "🔍 Проверка синтаксиса nginx..."
if sudo nginx -t; then
    log "✅ Синтаксис nginx корректен"
else
    error "❌ Ошибка в синтаксисе nginx!"
    log "🔄 Восстанавливаем резервную копию..."
    if [ -f "$BACKUP_DIR/nginx.conf.backup" ]; then
        sudo cp "$BACKUP_DIR/nginx.conf.backup" "$NGINX_CONFIG"
        sudo ln -sf "$NGINX_CONFIG" "$NGINX_ENABLED"
    fi
    exit 1
fi

# Запускаем nginx
log "▶️  Запуск nginx..."
sudo systemctl start nginx

# Проверяем статус
log "📊 Проверка статуса nginx..."
if sudo systemctl is-active --quiet nginx; then
    log "✅ Nginx запущен и работает"
else
    error "❌ Nginx не запустился!"
    exit 1
fi

# Тестируем endpoints
log "🔌 Тестирование WebSocket endpoint..."
WS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$NGINX_SITE/websocket || echo "000")
log "📊 WebSocket статус: $WS_STATUS"

if [ "$WS_STATUS" = "400" ]; then
    log "✅ WebSocket endpoint правильно отклоняет HTTP запросы (ожидаемо)"
elif [ "$WS_STATUS" = "101" ]; then
    log "✅ WebSocket endpoint работает"
else
    warning "⚠️  WebSocket endpoint вернул статус: $WS_STATUS"
fi

# Тестируем статус endpoint
log "📊 Тестирование статус endpoint..."
STATUS_RESPONSE=$(curl -s https://$NGINX_SITE/status | head -c 100)
if [[ "$STATUS_RESPONSE" == *"running"* ]]; then
    log "✅ Статус endpoint работает"
else
    warning "⚠️  Статус endpoint может не работать"
fi

# Тестируем тестовую страницу
log "🧪 Тестирование тестовой страницы..."
TEST_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$NGINX_SITE/websocket-test || echo "000")
log "📊 Тестовая страница статус: $TEST_STATUS"

if [ "$TEST_STATUS" = "200" ]; then
    log "✅ Тестовая страница доступна"
else
    warning "⚠️  Тестовая страница вернула статус: $TEST_STATUS"
fi

echo ""
log "🎉 Принудительное пересоздание nginx конфигурации завершено!"
log "🌐 Сайт доступен: https://$NGINX_SITE"
log "🔌 WebSocket endpoint: wss://$NGINX_SITE/websocket"
log "📊 Статус: https://$NGINX_SITE/status"
log "🧪 Тестовая страница: https://$NGINX_SITE/websocket-test"

echo ""
log "📋 Полезные команды:"
echo "  sudo nginx -t                    # Проверка синтаксиса"
echo "  sudo systemctl status nginx      # Статус nginx"
echo "  sudo tail -f /var/log/nginx/$NGINX_SITE.error.log  # Логи ошибок"
echo "  sudo tail -f /var/log/nginx/$NGINX_SITE.access.log # Логи доступа"
