#!/bin/bash

# Скрипт для настройки SSL сертификатов для qabase.ru
# Использование: ./setup-ssl.sh

set -e

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

log "🔒 Настраиваем SSL сертификаты для $NGINX_SITE..."

# Проверяем, установлен ли certbot
if ! command -v certbot &> /dev/null; then
    log "📦 Устанавливаем certbot..."
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
    log "✅ Certbot установлен"
fi

# Проверяем, что Nginx запущен
if ! sudo systemctl is-active --quiet nginx; then
    log "▶️  Запускаем Nginx..."
    sudo systemctl start nginx
fi

# Проверяем, что конфигурация Nginx активна
if [ ! -L "/etc/nginx/sites-enabled/$NGINX_SITE" ]; then
    error "❌ Конфигурация Nginx для $NGINX_SITE не активна. Сначала выполните ./check-nginx.sh"
fi

# Проверяем DNS
log "🔍 Проверяем DNS для $NGINX_SITE..."
DNS_IP=$(dig +short $NGINX_SITE | head -n1)
SERVER_IP=$(curl -s ifconfig.me)

if [ -z "$DNS_IP" ]; then
    error "❌ DNS запись для $NGINX_SITE не найдена. Настройте DNS перед получением SSL сертификата."
fi

if [ "$DNS_IP" != "$SERVER_IP" ]; then
    warning "⚠️  DNS запись для $NGINX_SITE ($DNS_IP) не указывает на этот сервер ($SERVER_IP)"
    warning "Обновите DNS запись перед получением SSL сертификата."
    exit 1
fi

log "✅ DNS запись корректна: $NGINX_SITE -> $DNS_IP"

# Получаем SSL сертификат
log "🔒 Получаем SSL сертификат для $NGINX_SITE и www.$NGINX_SITE..."
sudo certbot --nginx -d $NGINX_SITE -d www.$NGINX_SITE --non-interactive --agree-tos --email admin@$NGINX_SITE

# Проверяем, что сертификат получен
if [ -f "/etc/letsencrypt/live/$NGINX_SITE/fullchain.pem" ]; then
    log "✅ SSL сертификат успешно получен"
    
    # Проверяем срок действия
    CERT_EXPIRY=$(openssl x509 -enddate -noout -in /etc/letsencrypt/live/$NGINX_SITE/fullchain.pem | cut -d= -f2)
    log "📅 Сертификат действителен до: $CERT_EXPIRY"
    
    # Настраиваем автообновление
    log "🔄 Настраиваем автообновление сертификатов..."
    if ! sudo crontab -l | grep -q "certbot renew"; then
        (sudo crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | sudo crontab -
        log "✅ Автообновление сертификатов настроено"
    else
        log "✅ Автообновление сертификатов уже настроено"
    fi
    
    # Перезагружаем Nginx
    log "🔄 Перезагружаем Nginx..."
    sudo systemctl reload nginx
    
    # Тестируем HTTPS
    log "🧪 Тестируем HTTPS доступность..."
    sleep 2
    HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$NGINX_SITE || echo "000")
    
    if [ "$HTTPS_STATUS" = "200" ]; then
        log "✅ HTTPS доступен: https://$NGINX_SITE"
    else
        warning "⚠️  HTTPS недоступен (статус: $HTTPS_STATUS)"
    fi
    
    log "🎉 SSL сертификат настроен успешно!"
    log "🌐 Сайт доступен по адресу: https://$NGINX_SITE"
    
else
    error "❌ Не удалось получить SSL сертификат"
fi
