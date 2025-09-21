#!/bin/bash

# Скрипт для проверки и настройки Nginx для qabase.ru
# Использование: ./check-nginx.sh

set -e

PROJECT_DIR="/var/www/qabase"
NGINX_SITE="qabase.ru"
NGINX_CONFIG="/etc/nginx/sites-available/$NGINX_SITE"
NGINX_ENABLED="/etc/nginx/sites-enabled/$NGINX_SITE"

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

log "🔍 Проверяем настройку Nginx для $NGINX_SITE..."

# Проверяем, что мы в правильной директории
if [ ! -d "$PROJECT_DIR" ]; then
    error "Директория проекта не найдена: $PROJECT_DIR"
fi

cd $PROJECT_DIR

echo ""
log "1️⃣ Проверка Nginx конфигурации..."

# Проверяем, существует ли конфигурация
if [ -f "$NGINX_CONFIG" ]; then
    log "✅ Конфигурация Nginx найдена: $NGINX_CONFIG"
else
    error "❌ Конфигурация Nginx не найдена: $NGINX_CONFIG"
fi

# Проверяем, активирована ли конфигурация
if [ -L "$NGINX_ENABLED" ]; then
    log "✅ Конфигурация Nginx активирована: $NGINX_ENABLED"
else
    warning "⚠️  Конфигурация Nginx не активирована"
    log "🔧 Активируем конфигурацию..."
    sudo ln -sf $NGINX_CONFIG $NGINX_ENABLED
    log "✅ Конфигурация активирована"
fi

# Проверяем, отключен ли default сайт
if [ -L "/etc/nginx/sites-enabled/default" ]; then
    warning "⚠️  Default сайт Nginx активен, отключаем..."
    sudo rm -f /etc/nginx/sites-enabled/default
    log "✅ Default сайт отключен"
else
    log "✅ Default сайт Nginx отключен"
fi

echo ""
log "2️⃣ Проверка SSL сертификатов..."

# Проверяем SSL сертификаты
if [ -f "/etc/letsencrypt/live/$NGINX_SITE/fullchain.pem" ]; then
    log "✅ SSL сертификат найден: /etc/letsencrypt/live/$NGINX_SITE/fullchain.pem"
    
    # Проверяем срок действия сертификата
    CERT_EXPIRY=$(openssl x509 -enddate -noout -in /etc/letsencrypt/live/$NGINX_SITE/fullchain.pem | cut -d= -f2)
    log "📅 Сертификат действителен до: $CERT_EXPIRY"
else
    warning "⚠️  SSL сертификат не найден"
    log "🔧 Для получения SSL сертификата выполните:"
    echo "  sudo certbot --nginx -d $NGINX_SITE -d www.$NGINX_SITE"
fi

echo ""
log "3️⃣ Проверка синтаксиса Nginx..."

# Проверяем синтаксис конфигурации
if sudo nginx -t; then
    log "✅ Синтаксис Nginx конфигурации корректен"
else
    error "❌ Ошибка в синтаксисе Nginx конфигурации"
fi

echo ""
log "4️⃣ Проверка статуса Nginx..."

# Проверяем статус Nginx
if sudo systemctl is-active --quiet nginx; then
    log "✅ Nginx запущен"
else
    warning "⚠️  Nginx не запущен, запускаем..."
    sudo systemctl start nginx
    sudo systemctl enable nginx
    log "✅ Nginx запущен и включен автозапуск"
fi

echo ""
log "5️⃣ Перезагрузка Nginx..."

# Перезагружаем Nginx
sudo systemctl reload nginx
log "✅ Nginx перезагружен"

echo ""
log "6️⃣ Проверка портов..."

# Проверяем, слушает ли Nginx на портах 80 и 443
if sudo netstat -tlnp | grep -q ":80 "; then
    log "✅ Nginx слушает на порту 80"
else
    warning "⚠️  Nginx не слушает на порту 80"
fi

if sudo netstat -tlnp | grep -q ":443 "; then
    log "✅ Nginx слушает на порту 443"
else
    warning "⚠️  Nginx не слушает на порту 443"
fi

# Проверяем, слушает ли Go сервер на порту 9092
if sudo netstat -tlnp | grep -q ":9092"; then
    log "✅ Go WebSocket сервер слушает на порту 9092"
else
    warning "⚠️  Go WebSocket сервер не слушает на порту 9092"
fi

echo ""
log "7️⃣ Проверка DNS..."

# Проверяем DNS запись
log "🔍 Проверяем DNS для $NGINX_SITE..."
DNS_IP=$(dig +short $NGINX_SITE | head -n1)
SERVER_IP=$(curl -s ifconfig.me)

if [ -n "$DNS_IP" ]; then
    log "📡 DNS запись для $NGINX_SITE: $DNS_IP"
    log "🖥️  IP адрес сервера: $SERVER_IP"
    
    if [ "$DNS_IP" = "$SERVER_IP" ]; then
        log "✅ DNS запись указывает на этот сервер"
    else
        warning "⚠️  DNS запись не указывает на этот сервер"
        log "🔧 Обновите DNS запись для $NGINX_SITE на $SERVER_IP"
    fi
else
    warning "⚠️  Не удалось получить DNS запись для $NGINX_SITE"
fi

echo ""
log "8️⃣ Тестирование доступности..."

# Тестируем HTTP (должен редиректить на HTTPS)
log "🌐 Тестируем HTTP доступность..."
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
log "9️⃣ Рекомендации..."

# Даем рекомендации
if [ ! -f "/etc/letsencrypt/live/$NGINX_SITE/fullchain.pem" ]; then
    log "🔧 Для настройки SSL сертификата:"
    echo "  sudo certbot --nginx -d $NGINX_SITE -d www.$NGINX_SITE"
fi

if [ "$DNS_IP" != "$SERVER_IP" ]; then
    log "🔧 Для настройки DNS:"
    echo "  Обновите A-запись для $NGINX_SITE на $SERVER_IP"
fi

if [ "$HTTP_STATUS" != "301" ] && [ "$HTTP_STATUS" != "302" ]; then
    log "🔧 Для проверки конфигурации:"
    echo "  sudo nginx -t"
    echo "  sudo systemctl reload nginx"
fi

echo ""
log "🎯 Проверка Nginx завершена!"
log "📋 Сайт должен быть доступен по адресу: https://$NGINX_SITE"
