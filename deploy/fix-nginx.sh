#!/bin/bash

# Скрипт для исправления проблем с Nginx конфигурацией
# Использование: ./fix-nginx.sh

set -e

PROJECT_DIR="/var/www/qabase"
NGINX_SITE="qabase.ru"
NGINX_CONFIG="/etc/nginx/sites-available/$NGINX_SITE"
NGINX_ENABLED="/etc/nginx/sites-enabled/$NGINX_SITE"

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

log "🔧 Исправляем проблемы с Nginx конфигурацией для $NGINX_SITE..."

# Проверяем, что мы в правильной директории
if [ ! -d "$PROJECT_DIR" ]; then
    error "Директория проекта не найдена: $PROJECT_DIR"
fi

cd $PROJECT_DIR

# Останавливаем Nginx
log "⏹️  Останавливаем Nginx..."
sudo systemctl stop nginx || warning "Nginx не был запущен"

# Создаем резервную копию текущей конфигурации
if [ -f "$NGINX_CONFIG" ]; then
    log "💾 Создаем резервную копию текущей конфигурации..."
    sudo cp "$NGINX_CONFIG" "$NGINX_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
    log "✅ Резервная копия создана"
fi

# Копируем правильную конфигурацию
log "📄 Копируем правильную конфигурацию Nginx..."
sudo cp "$PROJECT_DIR/deploy/nginx-qabase.conf" "$NGINX_CONFIG"

# Проверяем синтаксис
log "🔍 Проверяем синтаксис конфигурации..."
if sudo nginx -t; then
    log "✅ Синтаксис конфигурации корректен"
else
    error "❌ Ошибка в синтаксисе конфигурации"
fi

# Убеждаемся, что конфигурация активирована
log "🔗 Активируем конфигурацию..."
sudo ln -sf "$NGINX_CONFIG" "$NGINX_ENABLED"

# Отключаем default сайт, если он активен
if [ -L "/etc/nginx/sites-enabled/default" ]; then
    log "🚫 Отключаем default сайт..."
    sudo rm -f /etc/nginx/sites-enabled/default
    log "✅ Default сайт отключен"
fi

# Запускаем Nginx
log "▶️  Запускаем Nginx..."
sudo systemctl start nginx

# Проверяем статус
log "🔍 Проверяем статус Nginx..."
if sudo systemctl is-active --quiet nginx; then
    log "✅ Nginx успешно запущен"
else
    error "❌ Не удалось запустить Nginx"
fi

# Проверяем порты
log "🔍 Проверяем порты..."
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

# Тестируем доступность
log "🧪 Тестируем доступность..."
sleep 2

# Тестируем HTTP (должен редиректить на HTTPS)
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
    HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$NGINX_SITE || echo "000")
    log "📊 HTTPS статус: $HTTPS_STATUS"
    
    if [ "$HTTPS_STATUS" = "200" ]; then
        log "✅ HTTPS доступен"
    else
        warning "⚠️  HTTPS недоступен (статус: $HTTPS_STATUS)"
    fi
fi

log "🎉 Исправление Nginx конфигурации завершено!"
log "🌐 Сайт должен быть доступен по адресу: https://$NGINX_SITE"
