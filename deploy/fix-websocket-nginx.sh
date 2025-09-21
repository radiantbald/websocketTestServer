#!/bin/bash

# Скрипт для исправления nginx конфигурации WebSocket
# Исправляет проблему с скачиванием файлов вместо WebSocket handshake

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для логирования
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Переменные
NGINX_SITE="qabase.ru"
NGINX_CONFIG="/etc/nginx/sites-available/$NGINX_SITE"
NGINX_ENABLED="/etc/nginx/sites-enabled/$NGINX_SITE"
BACKUP_DIR="/etc/nginx/backup-$(date +%Y%m%d-%H%M%S)"

log "🔧 Исправление nginx конфигурации для WebSocket..."

# Создаем резервную копию
log "📦 Создание резервной копии конфигурации..."
sudo mkdir -p "$BACKUP_DIR"
sudo cp "$NGINX_CONFIG" "$BACKUP_DIR/nginx.conf.backup"
log "✅ Резервная копия создана: $BACKUP_DIR"

# Копируем исправленную конфигурацию
log "📝 Копирование исправленной конфигурации..."
sudo cp "nginx-qabase.conf" "$NGINX_CONFIG"
log "✅ Конфигурация обновлена"

# Проверяем синтаксис nginx
log "🔍 Проверка синтаксиса nginx..."
if sudo nginx -t; then
    log "✅ Синтаксис nginx корректен"
else
    error "❌ Ошибка в синтаксисе nginx!"
    log "🔄 Восстанавливаем резервную копию..."
    sudo cp "$BACKUP_DIR/nginx.conf.backup" "$NGINX_CONFIG"
    exit 1
fi

# Перезагружаем nginx
log "🔄 Перезагрузка nginx..."
sudo systemctl reload nginx
log "✅ Nginx перезагружен"

# Проверяем статус nginx
log "📊 Проверка статуса nginx..."
if sudo systemctl is-active --quiet nginx; then
    log "✅ Nginx работает"
else
    error "❌ Nginx не работает!"
    exit 1
fi

# Тестируем WebSocket endpoint
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

echo ""
log "🎉 Исправление nginx конфигурации завершено!"
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
