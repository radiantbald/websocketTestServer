#!/bin/bash

# Скрипт для полного исправления проблемы с портами Nginx
# Использование: ./fix-ports.sh

set -e

PROJECT_DIR="/var/www/qabase"
NGINX_SITE="qabase.ru"

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

log "🔧 Полное исправление проблемы с портами Nginx для $NGINX_SITE..."

# Проверяем, что мы в правильной директории
if [ ! -d "$PROJECT_DIR" ]; then
    error "Директория проекта не найдена: $PROJECT_DIR"
fi

cd $PROJECT_DIR

echo ""
log "1️⃣ Освобождаем порты 80 и 443..."

# Освобождаем порты
./deploy/free-ports.sh

echo ""
log "2️⃣ Проверяем конфигурацию Nginx..."

# Проверяем синтаксис
log "🔍 Проверяем синтаксис конфигурации..."
if sudo nginx -t; then
    log "✅ Синтаксис конфигурации корректен"
else
    warning "⚠️  Ошибка в синтаксисе конфигурации"
    log "🔧 Исправляем конфигурацию..."
    ./deploy/fix-nginx.sh
fi

echo ""
log "3️⃣ Проверяем SSL сертификаты..."

# Проверяем SSL сертификаты
if [ -f "/etc/letsencrypt/live/$NGINX_SITE/fullchain.pem" ]; then
    log "✅ SSL сертификат найден"
    
    # Проверяем права доступа
    if sudo -u www-data test -r /etc/letsencrypt/live/$NGINX_SITE/fullchain.pem; then
        log "✅ Nginx может читать SSL сертификат"
    else
        warning "⚠️  Nginx не может читать SSL сертификат"
        log "🔧 Исправляем права доступа..."
        sudo chmod 644 /etc/letsencrypt/live/$NGINX_SITE/fullchain.pem
        sudo chmod 644 /etc/letsencrypt/live/$NGINX_SITE/privkey.pem
        log "✅ Права доступа исправлены"
    fi
else
    warning "⚠️  SSL сертификат не найден"
    log "🔧 Получаем SSL сертификат..."
    ./deploy/setup-ssl.sh
fi

echo ""
log "4️⃣ Финальная проверка Nginx..."

# Проверяем статус Nginx
if sudo systemctl is-active --quiet nginx; then
    log "✅ Nginx запущен"
else
    warning "⚠️  Nginx не запущен, запускаем..."
    sudo systemctl start nginx
    sleep 3
    
    if sudo systemctl is-active --quiet nginx; then
        log "✅ Nginx запущен"
    else
        error "❌ Не удалось запустить Nginx"
    fi
fi

echo ""
log "5️⃣ Тестируем доступность..."

# Тестируем HTTP (должен редиректить на HTTPS)
log "🧪 Тестируем HTTP доступность..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$NGINX_SITE || echo "000")
log "📊 HTTP статус: $HTTP_STATUS"

if [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
    log "✅ HTTP редирект работает"
elif [ "$HTTP_STATUS" = "200" ]; then
    warning "⚠️  HTTP возвращает 200 (нет редиректа на HTTPS)"
else
    warning "⚠️  HTTP недоступен (статус: $HTTP_STATUS)"
fi

# Тестируем HTTPS (если есть сертификат)
if [ -f "/etc/letsencrypt/live/$NGINX_SITE/fullchain.pem" ]; then
    log "🔒 Тестируем HTTPS доступность..."
    HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$NGINX_SITE || echo "000")
    log "📊 HTTPS статус: $HTTPS_STATUS"
    
    if [ "$HTTPS_STATUS" = "200" ]; then
        log "✅ HTTPS доступен"
    else
        warning "⚠️  HTTPS недоступен (статус: $HTTPS_STATUS)"
    fi
fi

echo ""
log "6️⃣ Проверяем WebSocket endpoint..."

# Тестируем WebSocket endpoint
log "🔌 Тестируем WebSocket endpoint..."
WS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$NGINX_SITE/ws || echo "000")
log "📊 WebSocket статус: $WS_STATUS"

if [ "$WS_STATUS" = "101" ] || [ "$WS_STATUS" = "200" ]; then
    log "✅ WebSocket endpoint доступен"
else
    warning "⚠️  WebSocket endpoint недоступен (статус: $WS_STATUS)"
fi

echo ""
log "7️⃣ Проверяем статус сервиса..."

# Проверяем статус WebSocket сервиса
if sudo systemctl is-active --quiet websocket-server; then
    log "✅ WebSocket сервис запущен"
else
    warning "⚠️  WebSocket сервис не запущен"
    log "🔧 Запускаем WebSocket сервис..."
    sudo systemctl start websocket-server
    sleep 2
    
    if sudo systemctl is-active --quiet websocket-server; then
        log "✅ WebSocket сервис запущен"
    else
        warning "⚠️  Не удалось запустить WebSocket сервис"
    fi
fi

echo ""
log "🎉 Полное исправление завершено!"
log "🌐 Сайт должен быть доступен по адресу: https://$NGINX_SITE"
log "🔌 WebSocket endpoint: https://$NGINX_SITE/ws"
log "📊 Статус API: https://$NGINX_SITE/status"
