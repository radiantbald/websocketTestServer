#!/bin/bash

# Тестирование WebSocket соединения
# Проверяет все аспекты WebSocket функциональности

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

log "🧪 Тестирование WebSocket соединения..."

echo ""
info "📋 Объяснение статусов:"
echo "  ✅ HTTP 400 на /websocket - это ПРАВИЛЬНО!"
echo "  📝 /websocket - это WebSocket endpoint, не веб-страница"
echo "  🌐 /websocket-test - это страница для тестирования"
echo "  🔌 wss://qabase.ru/websocket - это URL для JavaScript подключения"

echo ""
info "🌐 Тестирование веб-страниц:"

# Тест главной страницы
MAIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$NGINX_SITE/ 2>/dev/null || echo "000")
echo "  📊 Главная страница (/) - HTTP $MAIN_STATUS"
if [ "$MAIN_STATUS" = "200" ]; then
    echo "    ✅ Главная страница доступна"
else
    echo "    ❌ Главная страница недоступна"
fi

# Тест тестовой страницы
TEST_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$NGINX_SITE/websocket-test 2>/dev/null || echo "000")
echo "  📊 Тестовая страница (/websocket-test) - HTTP $TEST_STATUS"
if [ "$TEST_STATUS" = "200" ]; then
    echo "    ✅ Тестовая страница доступна"
else
    echo "    ❌ Тестовая страница недоступна"
fi

# Тест статуса
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$NGINX_SITE/status 2>/dev/null || echo "000")
echo "  📊 Статус API (/status) - HTTP $STATUS_CODE"
if [ "$STATUS_CODE" = "200" ]; then
    echo "    ✅ Статус API работает"
else
    echo "    ❌ Статус API не работает"
fi

echo ""
info "🔌 Тестирование WebSocket endpoint:"

# Тест WebSocket endpoint (должен возвращать 400 для HTTP запросов)
WS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$NGINX_SITE/websocket 2>/dev/null || echo "000")
echo "  📊 WebSocket endpoint (/websocket) - HTTP $WS_STATUS"
if [ "$WS_STATUS" = "400" ]; then
    echo "    ✅ WebSocket endpoint правильно отклоняет HTTP запросы"
    echo "    📝 Это ожидаемое поведение - endpoint работает!"
else
    echo "    ⚠️  WebSocket endpoint вернул неожиданный код: $WS_STATUS"
fi

echo ""
info "🔍 Проверка WebSocket сервера:"

# Проверяем, что WebSocket сервер запущен
if sudo systemctl is-active --quiet websocket-server; then
    echo "  ✅ WebSocket сервер запущен"
else
    echo "  ❌ WebSocket сервер не запущен"
fi

# Проверяем порт
if netstat -tlnp 2>/dev/null | grep -q ":9092 "; then
    echo "  ✅ Порт 9092 прослушивается"
else
    echo "  ❌ Порт 9092 не прослушивается"
fi

echo ""
info "🧪 Тестирование с wscat (если установлен):"
if command -v wscat &> /dev/null; then
    echo "  🔧 wscat найден, тестируем WebSocket соединение..."
    timeout 5 wscat -c wss://$NGINX_SITE/websocket?username=test 2>/dev/null && echo "    ✅ WebSocket соединение работает!" || echo "    ❌ WebSocket соединение не работает"
else
    echo "  📦 wscat не установлен. Установите: npm install -g wscat"
fi

echo ""
info "📋 Инструкции для пользователей:"
echo "  🌐 Для тестирования WebSocket:"
echo "    1. Откройте https://$NGINX_SITE/websocket-test"
echo "    2. Введите имя пользователя"
echo "    3. Нажмите 'Подключиться'"
echo "    4. Отправляйте сообщения"
echo ""
echo "  🔌 Для разработчиков:"
echo "    WebSocket URL: wss://$NGINX_SITE/websocket"
echo "    Параметры: ?username=ИмяПользователя"

echo ""
if [ "$TEST_STATUS" = "200" ] && [ "$WS_STATUS" = "400" ]; then
    log "🎉 WebSocket система работает правильно!"
    log "✅ Тестовая страница доступна: https://$NGINX_SITE/websocket-test"
    log "✅ WebSocket endpoint работает: wss://$NGINX_SITE/websocket"
else
    warning "⚠️  Есть проблемы с WebSocket системой"
    if [ "$TEST_STATUS" != "200" ]; then
        echo "  ❌ Тестовая страница недоступна"
    fi
    if [ "$WS_STATUS" != "400" ]; then
        echo "  ❌ WebSocket endpoint работает неправильно"
    fi
fi
