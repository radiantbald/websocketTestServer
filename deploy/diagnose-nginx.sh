#!/bin/bash

# Диагностика nginx конфигурации
# Показывает текущее состояние и проблемы

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

info() {
    echo -e "\033[0;34m[$(date +'%H:%M:%S')] INFO: $1\033[0m"
}

NGINX_SITE="qabase.ru"
NGINX_CONFIG="/etc/nginx/sites-available/$NGINX_SITE"
NGINX_ENABLED="/etc/nginx/sites-enabled/$NGINX_SITE"

log "🔍 Диагностика nginx конфигурации..."

echo ""
info "📋 Проверка файлов конфигурации:"
if [ -f "$NGINX_CONFIG" ]; then
    echo "  ✅ $NGINX_CONFIG - существует"
else
    echo "  ❌ $NGINX_CONFIG - не найден"
fi

if [ -L "$NGINX_ENABLED" ]; then
    echo "  ✅ $NGINX_ENABLED - символическая ссылка существует"
    echo "  📎 Ссылается на: $(readlink $NGINX_ENABLED)"
else
    echo "  ❌ $NGINX_ENABLED - символическая ссылка не найдена"
fi

echo ""
info "🔍 Проверка синтаксиса nginx:"
if sudo nginx -t 2>&1; then
    echo "  ✅ Синтаксис nginx корректен"
else
    echo "  ❌ Ошибки в синтаксисе nginx"
fi

echo ""
info "📊 Статус nginx сервиса:"
if sudo systemctl is-active --quiet nginx; then
    echo "  ✅ Nginx запущен"
else
    echo "  ❌ Nginx не запущен"
fi

echo ""
info "🔍 Поиск дублирующихся location блоков:"
if [ -f "$NGINX_CONFIG" ]; then
    WEBSOCKET_COUNT=$(grep -c "location /websocket" "$NGINX_CONFIG" || echo "0")
    echo "  📊 Найдено location /websocket блоков: $WEBSOCKET_COUNT"
    
    if [ "$WEBSOCKET_COUNT" -gt 1 ]; then
        error "  ❌ Обнаружены дублирующиеся location /websocket блоки!"
        echo "  📍 Строки с location /websocket:"
        grep -n "location /websocket" "$NGINX_CONFIG" | sed 's/^/    /'
    elif [ "$WEBSOCKET_COUNT" -eq 1 ]; then
        echo "  ✅ Найден один location /websocket блок"
    else
        warning "  ⚠️  Location /websocket блоки не найдены"
    fi
else
    echo "  ❌ Файл конфигурации не найден"
fi

echo ""
info "🔍 Поиск других location блоков:"
if [ -f "$NGINX_CONFIG" ]; then
    echo "  📊 Все location блоки:"
    grep -n "location " "$NGINX_CONFIG" | sed 's/^/    /'
fi

echo ""
info "🌐 Тестирование endpoints:"
# Тест WebSocket endpoint
WS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$NGINX_SITE/websocket 2>/dev/null || echo "000")
echo "  📊 WebSocket endpoint (/websocket): $WS_STATUS"

# Тест статус endpoint
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$NGINX_SITE/status 2>/dev/null || echo "000")
echo "  📊 Статус endpoint (/status): $STATUS_CODE"

# Тест тестовой страницы
TEST_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$NGINX_SITE/websocket-test 2>/dev/null || echo "000")
echo "  📊 Тестовая страница (/websocket-test): $TEST_CODE"

# Тест главной страницы
MAIN_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$NGINX_SITE/ 2>/dev/null || echo "000")
echo "  📊 Главная страница (/): $MAIN_CODE"

echo ""
info "📋 Рекомендации:"
if [ "$WEBSOCKET_COUNT" -gt 1 ]; then
    echo "  🔧 Запустите: ./deploy/force-recreate-nginx.sh"
    echo "  🔧 Или: ./deploy/simple-nginx-fix.sh"
elif [ "$WEBSOCKET_COUNT" -eq 0 ]; then
    echo "  🔧 Запустите: ./deploy/force-recreate-nginx.sh"
elif [ "$WS_STATUS" = "000" ]; then
    echo "  🔧 Проверьте, что WebSocket сервер запущен на порту 9092"
    echo "  🔧 Запустите: sudo systemctl status websocket-server"
else
    echo "  ✅ Конфигурация выглядит корректно"
fi

echo ""
log "🎯 Диагностика завершена!"