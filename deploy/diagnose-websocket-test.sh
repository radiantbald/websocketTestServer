#!/bin/bash

# Диагностика проблемы с тестовой страницей WebSocket
# Выясняет, почему файл скачивается вместо отображения

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

NGINX_CONFIG="/etc/nginx/sites-available/qabase.ru"
PROJECT_DIR="/var/www/qabase"

log "🔍 Диагностика проблемы с тестовой страницей WebSocket..."

echo ""
info "📁 Проверка файлов:"
if [ -f "$PROJECT_DIR/client/test-client.html" ]; then
    echo "  ✅ Файл test-client.html существует"
    FILE_SIZE=$(ls -lh "$PROJECT_DIR/client/test-client.html" | awk '{print $5}')
    echo "  📊 Размер файла: $FILE_SIZE"
    
    # Проверяем первые строки файла
    echo "  📄 Первые 3 строки файла:"
    head -3 "$PROJECT_DIR/client/test-client.html" | sed 's/^/    /'
else
    echo "  ❌ Файл test-client.html не найден"
fi

echo ""
info "🔍 Проверка nginx конфигурации:"
if [ -f "$NGINX_CONFIG" ]; then
    echo "  ✅ Файл конфигурации nginx существует"
    
    # Ищем блок websocket-test
    if grep -q "location.*websocket-test" "$NGINX_CONFIG"; then
        echo "  ✅ Блок websocket-test найден в конфигурации"
        echo "  📄 Содержимое блока:"
        sed -n '/location.*websocket-test/,/}/p' "$NGINX_CONFIG" | sed 's/^/    /'
    else
        echo "  ❌ Блок websocket-test не найден в конфигурации"
    fi
else
    echo "  ❌ Файл конфигурации nginx не найден"
fi

echo ""
info "🌐 Тестирование HTTP запросов:"

# Детальный тест
echo "  📊 Детальный тест /websocket-test:"
curl -s -I https://qabase.ru/websocket-test 2>/dev/null | while read line; do
    echo "    $line"
done

echo ""
echo "  📊 Тест с сохранением файла:"
curl -s -o /tmp/websocket-test-response.html https://qabase.ru/websocket-test 2>/dev/null
if [ -f "/tmp/websocket-test-response.html" ]; then
    RESPONSE_SIZE=$(ls -lh /tmp/websocket-test-response.html | awk '{print $5}')
    echo "    📁 Размер ответа: $RESPONSE_SIZE"
    echo "    📄 Первые 3 строки ответа:"
    head -3 /tmp/websocket-test-response.html | sed 's/^/      /'
    
    # Проверяем, это HTML или что-то другое
    if head -1 /tmp/websocket-test-response.html | grep -q "<!DOCTYPE\|<html"; then
        echo "    ✅ Ответ содержит HTML"
    else
        echo "    ❌ Ответ не содержит HTML"
    fi
fi

echo ""
info "🔍 Проверка прав доступа:"
if [ -d "$PROJECT_DIR/client" ]; then
    echo "  📁 Права на директорию client:"
    ls -ld "$PROJECT_DIR/client" | sed 's/^/    /'
    
    echo "  📄 Права на файл test-client.html:"
    ls -l "$PROJECT_DIR/client/test-client.html" | sed 's/^/    /'
fi

echo ""
info "🔍 Проверка nginx процессов:"
if pgrep nginx > /dev/null; then
    echo "  ✅ Nginx запущен"
    echo "  📊 Процессы nginx:"
    ps aux | grep nginx | grep -v grep | sed 's/^/    /'
else
    echo "  ❌ Nginx не запущен"
fi

echo ""
info "🔍 Проверка логов nginx:"
if [ -f "/var/log/nginx/qabase.ru.error.log" ]; then
    echo "  📄 Последние ошибки nginx:"
    tail -5 /var/log/nginx/qabase.ru.error.log | sed 's/^/    /'
else
    echo "  ⚠️  Лог ошибок nginx не найден"
fi

echo ""
info "🔧 Рекомендации:"
echo "  🚀 Попробуйте: ./deploy/fix-websocket-test-page-v2.sh"
echo "  🔄 Или: ./deploy/force-recreate-nginx.sh"
echo "  📋 Проверьте логи: sudo tail -f /var/log/nginx/qabase.ru.error.log"

echo ""
log "🎯 Диагностика завершена!"
