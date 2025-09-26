#!/bin/bash

# Скрипт для быстрого исправления nginx конфигурации на сервере

echo "🔧 Исправляем nginx конфигурацию..."

# Обновляем код
echo "📥 Обновляем код..."
git pull origin main

# Заменяем конфигурацию nginx
echo "🔄 Заменяем конфигурацию nginx..."
cp deploy/nginx-qabase-fixed.conf /etc/nginx/sites-available/qabase.ru

# Проверяем конфигурацию
echo "✅ Проверяем конфигурацию nginx..."
if nginx -t; then
    echo "✅ Конфигурация nginx корректна"
    
    # Перезапускаем nginx
    echo "🔄 Перезапускаем nginx..."
    systemctl restart nginx
    
    # Проверяем статус
    echo "📊 Проверяем статус nginx..."
    systemctl status nginx --no-pager
    
    echo "✅ Nginx исправлен и перезапущен!"
    echo "🌐 Теперь проверьте: https://qabase.ru/websocket"
else
    echo "❌ Ошибка в конфигурации nginx!"
    echo "📋 Проверьте логи: tail -f /var/log/nginx/error.log"
    exit 1
fi
