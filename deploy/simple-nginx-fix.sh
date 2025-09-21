#!/bin/bash

# Простое исправление nginx конфигурации
# Заменяет всю конфигурацию на исправленную

set -e

log() {
    echo -e "\033[0;32m[$(date +'%H:%M:%S')] $1\033[0m"
}

error() {
    echo -e "\033[0;31m[$(date +'%H:%M:%S')] ERROR: $1\033[0m"
}

NGINX_CONFIG="/etc/nginx/sites-available/qabase.ru"

log "🔧 Простое исправление nginx конфигурации..."

# Создаем резервную копию
BACKUP_FILE="$NGINX_CONFIG.backup.$(date +%Y%m%d-%H%M%S)"
sudo cp "$NGINX_CONFIG" "$BACKUP_FILE"
log "📦 Резервная копия создана: $BACKUP_FILE"

# Получаем путь к директории скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Проверяем наличие исправленной конфигурации
if [ ! -f "$SCRIPT_DIR/nginx-qabase-clean.conf" ]; then
    error "❌ Файл nginx-qabase-clean.conf не найден в $SCRIPT_DIR"
    exit 1
fi

# Заменяем конфигурацию
log "📝 Замена конфигурации на исправленную..."
sudo cp "$SCRIPT_DIR/nginx-qabase-clean.conf" "$NGINX_CONFIG"

# Проверяем синтаксис
log "🔍 Проверка синтаксиса..."
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

log "🎉 Исправление завершено!"
log "🌐 Сайт: https://qabase.ru"
log "🔌 WebSocket: wss://qabase.ru/websocket"
log "🧪 Тест: https://qabase.ru/websocket-test"
