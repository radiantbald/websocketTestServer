#!/bin/bash

# Скрипт для диагностики проблем с запуском Nginx
# Использование: ./diagnose-nginx.sh

set -e

NGINX_SITE="qabase.ru"

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

log "🔍 Диагностика проблем с запуском Nginx..."

echo ""
log "1️⃣ Проверка статуса Nginx..."

# Проверяем статус Nginx
log "📊 Статус сервиса Nginx:"
sudo systemctl status nginx --no-pager || warning "Не удалось получить статус"

echo ""
log "2️⃣ Проверка логов Nginx..."

# Показываем последние логи
log "📋 Последние логи Nginx:"
sudo journalctl -u nginx -n 20 --no-pager || warning "Нет логов Nginx"

echo ""
log "3️⃣ Проверка конфигурации..."

# Проверяем синтаксис
log "🔍 Проверка синтаксиса конфигурации:"
sudo nginx -t || warning "Ошибка в синтаксисе"

echo ""
log "4️⃣ Проверка портов..."

# Проверяем, заняты ли порты 80 и 443
log "🔍 Проверяем порты 80 и 443:"
if sudo netstat -tlnp | grep -q ":80 "; then
    log "⚠️  Порт 80 занят:"
    sudo netstat -tlnp | grep ":80 "
else
    log "✅ Порт 80 свободен"
fi

if sudo netstat -tlnp | grep -q ":443 "; then
    log "⚠️  Порт 443 занят:"
    sudo netstat -tlnp | grep ":443 "
else
    log "✅ Порт 443 свободен"
fi

echo ""
log "5️⃣ Проверка файлов конфигурации..."

# Проверяем файлы конфигурации
log "📄 Проверяем файлы конфигурации:"
if [ -f "/etc/nginx/sites-available/$NGINX_SITE" ]; then
    log "✅ Конфигурация найдена: /etc/nginx/sites-available/$NGINX_SITE"
else
    error "❌ Конфигурация не найдена: /etc/nginx/sites-available/$NGINX_SITE"
fi

if [ -L "/etc/nginx/sites-enabled/$NGINX_SITE" ]; then
    log "✅ Конфигурация активирована: /etc/nginx/sites-enabled/$NGINX_SITE"
else
    warning "⚠️  Конфигурация не активирована"
fi

echo ""
log "6️⃣ Проверка SSL сертификатов..."

# Проверяем SSL сертификаты
if [ -f "/etc/letsencrypt/live/$NGINX_SITE/fullchain.pem" ]; then
    log "✅ SSL сертификат найден"
    
    # Проверяем права доступа
    CERT_PERMS=$(ls -la /etc/letsencrypt/live/$NGINX_SITE/fullchain.pem | awk '{print $1}')
    log "📋 Права на сертификат: $CERT_PERMS"
    
    # Проверяем, может ли Nginx читать сертификат
    if sudo -u www-data test -r /etc/letsencrypt/live/$NGINX_SITE/fullchain.pem; then
        log "✅ Nginx может читать SSL сертификат"
    else
        warning "⚠️  Nginx не может читать SSL сертификат"
    fi
else
    warning "⚠️  SSL сертификат не найден"
fi

echo ""
log "7️⃣ Проверка процессов..."

# Проверяем, есть ли процессы Nginx
if pgrep nginx > /dev/null; then
    log "⚠️  Найдены процессы Nginx:"
    ps aux | grep nginx | grep -v grep
else
    log "✅ Процессы Nginx не найдены"
fi

echo ""
log "8️⃣ Проверка прав доступа..."

# Проверяем права на директории
log "🔐 Проверяем права доступа:"
ls -la /etc/nginx/sites-available/ | grep $NGINX_SITE
ls -la /etc/nginx/sites-enabled/ | grep $NGINX_SITE

echo ""
log "9️⃣ Попытка запуска с диагностикой..."

# Пытаемся запустить Nginx с подробным выводом
log "🧪 Пытаемся запустить Nginx..."
sudo systemctl start nginx 2>&1 || warning "Не удалось запустить Nginx"

# Ждем немного
sleep 2

# Проверяем статус
if sudo systemctl is-active --quiet nginx; then
    log "✅ Nginx запущен успешно"
else
    warning "⚠️  Nginx не запустился"
    
    # Показываем дополнительные логи
    log "📋 Дополнительные логи:"
    sudo journalctl -u nginx -n 10 --no-pager
fi

echo ""
log "🔟 Рекомендации по исправлению..."

# Даем рекомендации
if sudo netstat -tlnp | grep -q ":80 "; then
    log "🔧 Рекомендация: Освободите порт 80"
    echo "  sudo fuser -k 80/tcp"
fi

if sudo netstat -tlnp | grep -q ":443 "; then
    log "🔧 Рекомендация: Освободите порт 443"
    echo "  sudo fuser -k 443/tcp"
fi

if [ ! -L "/etc/nginx/sites-enabled/$NGINX_SITE" ]; then
    log "🔧 Рекомендация: Активируйте конфигурацию"
    echo "  sudo ln -sf /etc/nginx/sites-available/$NGINX_SITE /etc/nginx/sites-enabled/"
fi

if [ ! -f "/etc/letsencrypt/live/$NGINX_SITE/fullchain.pem" ]; then
    log "🔧 Рекомендация: Получите SSL сертификат"
    echo "  sudo certbot --nginx -d $NGINX_SITE -d www.$NGINX_SITE"
fi

if pgrep nginx > /dev/null; then
    log "🔧 Рекомендация: Завершите все процессы Nginx"
    echo "  sudo pkill nginx"
    echo "  sudo systemctl stop nginx"
fi

log "🔧 Рекомендация: Попробуйте перезапустить Nginx"
echo "  sudo systemctl restart nginx"

echo ""
log "🎯 Диагностика завершена!"
log "📋 Следуйте рекомендациям выше для исправления проблем"
