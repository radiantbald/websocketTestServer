#!/bin/bash

# Скрипт для освобождения портов 80 и 443
# Использование: ./free-ports.sh

set -e

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

log "🔓 Освобождаем порты 80 и 443 для Nginx..."

echo ""
log "1️⃣ Проверяем, что занимает порты 80 и 443..."

# Проверяем порт 80
if sudo netstat -tlnp | grep -q ":80 "; then
    log "⚠️  Порт 80 занят:"
    sudo netstat -tlnp | grep ":80 "
    
    # Показываем процесс
    PORT80_PID=$(sudo netstat -tlnp | grep ":80 " | awk '{print $7}' | cut -d'/' -f1)
    if [ -n "$PORT80_PID" ] && [ "$PORT80_PID" != "-" ]; then
        log "🔍 Процесс на порту 80:"
        ps aux | grep $PORT80_PID | grep -v grep
    fi
else
    log "✅ Порт 80 свободен"
fi

# Проверяем порт 443
if sudo netstat -tlnp | grep -q ":443 "; then
    log "⚠️  Порт 443 занят:"
    sudo netstat -tlnp | grep ":443 "
    
    # Показываем процесс
    PORT443_PID=$(sudo netstat -tlnp | grep ":443 " | awk '{print $7}' | cut -d'/' -f1)
    if [ -n "$PORT443_PID" ] && [ "$PORT443_PID" != "-" ]; then
        log "🔍 Процесс на порту 443:"
        ps aux | grep $PORT443_PID | grep -v grep
    fi
else
    log "✅ Порт 443 свободен"
fi

echo ""
log "2️⃣ Освобождаем порты..."

# Освобождаем порт 80
if sudo netstat -tlnp | grep -q ":80 "; then
    log "🔓 Освобождаем порт 80..."
    sudo fuser -k 80/tcp || warning "Не удалось освободить порт 80"
    sleep 2
    
    # Проверяем, освободился ли порт
    if sudo netstat -tlnp | grep -q ":80 "; then
        warning "⚠️  Порт 80 все еще занят, принудительно завершаем процессы..."
        sudo pkill -f ":80" || true
        sudo pkill -f "nginx" || true
        sleep 2
    else
        log "✅ Порт 80 освобожден"
    fi
fi

# Освобождаем порт 443
if sudo netstat -tlnp | grep -q ":443 "; then
    log "🔓 Освобождаем порт 443..."
    sudo fuser -k 443/tcp || warning "Не удалось освободить порт 443"
    sleep 2
    
    # Проверяем, освободился ли порт
    if sudo netstat -tlnp | grep -q ":443 "; then
        warning "⚠️  Порт 443 все еще занят, принудительно завершаем процессы..."
        sudo pkill -f ":443" || true
        sudo pkill -f "nginx" || true
        sleep 2
    else
        log "✅ Порт 443 освобожден"
    fi
fi

echo ""
log "3️⃣ Завершаем все процессы Nginx..."

# Завершаем все процессы Nginx
sudo pkill -f nginx || warning "Процессы Nginx не найдены"
sudo systemctl stop nginx || warning "Сервис Nginx не был запущен"

# Ждем завершения процессов
sleep 3

echo ""
log "4️⃣ Проверяем, что порты свободны..."

# Проверяем порт 80
if sudo netstat -tlnp | grep -q ":80 "; then
    warning "⚠️  Порт 80 все еще занят:"
    sudo netstat -tlnp | grep ":80 "
else
    log "✅ Порт 80 свободен"
fi

# Проверяем порт 443
if sudo netstat -tlnp | grep -q ":443 "; then
    warning "⚠️  Порт 443 все еще занят:"
    sudo netstat -tlnp | grep ":443 "
else
    log "✅ Порт 443 свободен"
fi

echo ""
log "5️⃣ Проверяем, что нет процессов Nginx..."

# Проверяем процессы Nginx
if pgrep nginx > /dev/null; then
    warning "⚠️  Найдены процессы Nginx:"
    ps aux | grep nginx | grep -v grep
    log "🔓 Принудительно завершаем..."
    sudo pkill -9 nginx || true
    sleep 2
else
    log "✅ Процессы Nginx не найдены"
fi

echo ""
log "6️⃣ Пытаемся запустить Nginx..."

# Пытаемся запустить Nginx
log "▶️  Запускаем Nginx..."
sudo systemctl start nginx

# Ждем запуска
sleep 3

# Проверяем статус
if sudo systemctl is-active --quiet nginx; then
    log "✅ Nginx успешно запущен"
    
    # Проверяем порты
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
else
    warning "⚠️  Nginx не запустился, показываем диагностику..."
    sudo systemctl status nginx --no-pager
    log "📋 Последние логи:"
    sudo journalctl -u nginx -n 10 --no-pager
    error "❌ Не удалось запустить Nginx. Проверьте логи выше."
fi

echo ""
log "7️⃣ Тестируем доступность..."

# Тестируем HTTP
log "🧪 Тестируем HTTP доступность..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost || echo "000")
log "📊 HTTP статус: $HTTP_STATUS"

if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
    log "✅ HTTP доступен"
else
    warning "⚠️  HTTP недоступен (статус: $HTTP_STATUS)"
fi

log "🎉 Освобождение портов завершено!"
log "🌐 Nginx должен быть доступен на портах 80 и 443"
