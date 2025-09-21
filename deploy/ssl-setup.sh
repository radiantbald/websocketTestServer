#!/bin/bash

# Скрипт для настройки SSL сертификатов для qabase.ru
# Использование: ./ssl-setup.sh

set -e

echo "🔒 Настройка SSL сертификатов для qabase.ru..."

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

# Проверяем наличие certbot
if ! command -v certbot &> /dev/null; then
    log "Устанавливаем certbot..."
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
fi

# Проверяем, что nginx конфигурация существует
if [ ! -f "/etc/nginx/sites-available/qabase.ru" ]; then
    error "Сначала запустите deploy.sh для создания nginx конфигурации"
fi

log "Получаем SSL сертификат от Let's Encrypt..."
sudo certbot --nginx -d qabase.ru -d www.qabase.ru --non-interactive --agree-tos --email admin@qabase.ru

log "Проверяем автоматическое обновление сертификатов..."
if sudo systemctl is-active --quiet certbot.timer; then
    log "✅ Автоматическое обновление сертификатов уже настроено"
else
    log "Настраиваем автоматическое обновление сертификатов..."
    sudo systemctl enable certbot.timer
    sudo systemctl start certbot.timer
fi

log "Проверяем SSL сертификат..."
if sudo certbot certificates | grep -q "qabase.ru"; then
    log "✅ SSL сертификат успешно установлен"
else
    error "❌ Ошибка установки SSL сертификата"
fi

log "Проверяем доступность HTTPS..."
sleep 2
if curl -f -s https://qabase.ru/status > /dev/null; then
    log "✅ HTTPS работает корректно"
else
    warning "⚠️  HTTPS может быть недоступен, проверьте настройки"
fi

log "🎉 SSL настройка завершена!"
log "Сайт доступен по HTTPS: https://qabase.ru"
log "WebSocket endpoint: wss://qabase.ru/ws"

echo ""
log "Полезные команды:"
echo "  sudo certbot certificates              # Список сертификатов"
echo "  sudo certbot renew --dry-run          # Тест обновления"
echo "  sudo certbot renew                    # Обновление сертификатов"
echo "  sudo systemctl status certbot.timer   # Статус автообновления"
