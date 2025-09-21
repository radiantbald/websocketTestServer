#!/bin/bash

# Скрипт диагностики проблем с systemd сервисом
# Использование: ./diagnose-service.sh

set -e

PROJECT_DIR="/var/www/qabase"
SERVICE_NAME="websocket-server"

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
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

log "🔍 Диагностика сервиса $SERVICE_NAME..."

# Проверяем, что мы в правильной директории
if [ ! -d "$PROJECT_DIR" ]; then
    error "Директория проекта не найдена: $PROJECT_DIR"
    exit 1
fi

cd $PROJECT_DIR

echo ""
log "1️⃣ Проверка systemd сервиса..."

# Проверяем, существует ли сервис
if sudo systemctl list-unit-files | grep -q "$SERVICE_NAME.service"; then
    log "✅ Сервис $SERVICE_NAME найден в systemd"
else
    error "❌ Сервис $SERVICE_NAME не найден в systemd"
fi

# Проверяем статус сервиса
log "📊 Статус сервиса:"
sudo systemctl status $SERVICE_NAME --no-pager || warning "Не удалось получить статус"

echo ""
log "2️⃣ Проверка файлов проекта..."

# Проверяем бинарный файл
if [ -f "$PROJECT_DIR/server/websocket-server" ]; then
    log "✅ Бинарный файл найден: $PROJECT_DIR/server/websocket-server"
    ls -la $PROJECT_DIR/server/websocket-server
else
    error "❌ Бинарный файл не найден: $PROJECT_DIR/server/websocket-server"
fi

# Проверяем конфигурацию сервиса
if [ -f "$PROJECT_DIR/deploy/websocket-server.service" ]; then
    log "✅ Конфигурация сервиса найдена: $PROJECT_DIR/deploy/websocket-server.service"
else
    error "❌ Конфигурация сервиса не найдена: $PROJECT_DIR/deploy/websocket-server.service"
fi

# Проверяем systemd файл
if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
    log "✅ Systemd файл найден: /etc/systemd/system/$SERVICE_NAME.service"
else
    error "❌ Systemd файл не найден: /etc/systemd/system/$SERVICE_NAME.service"
fi

echo ""
log "3️⃣ Проверка прав доступа..."

# Проверяем права на бинарный файл
BINARY_PERMS=$(ls -la $PROJECT_DIR/server/websocket-server | awk '{print $1}')
BINARY_OWNER=$(ls -la $PROJECT_DIR/server/websocket-server | awk '{print $3":"$4}')

log "📋 Права на бинарный файл: $BINARY_PERMS, владелец: $BINARY_OWNER"

if [[ "$BINARY_PERMS" == *"x"* ]]; then
    log "✅ Бинарный файл исполняемый"
else
    error "❌ Бинарный файл не исполняемый"
fi

if [ "$BINARY_OWNER" = "www-data:www-data" ]; then
    log "✅ Правильный владелец файла"
else
    warning "⚠️  Неправильный владелец файла. Ожидается: www-data:www-data, получено: $BINARY_OWNER"
fi

echo ""
log "4️⃣ Проверка запуска бинарного файла..."

# Проверяем, запускается ли бинарный файл
log "🧪 Тестируем запуск бинарного файла..."
timeout 5 sudo -u www-data $PROJECT_DIR/server/websocket-server --help 2>&1 || warning "Бинарный файл не запускается или не поддерживает --help"

echo ""
log "5️⃣ Проверка портов..."

# Проверяем, занят ли порт 9092
if sudo netstat -tlnp | grep -q ":9092"; then
    log "⚠️  Порт 9092 занят:"
    sudo netstat -tlnp | grep ":9092"
else
    log "✅ Порт 9092 свободен"
fi

echo ""
log "6️⃣ Проверка логов..."

# Показываем последние логи
log "📋 Последние логи сервиса:"
sudo journalctl -u $SERVICE_NAME -n 20 --no-pager || warning "Нет логов сервиса"

echo ""
log "7️⃣ Проверка конфигурации systemd..."

# Показываем конфигурацию сервиса
log "📋 Конфигурация сервиса:"
sudo systemctl cat $SERVICE_NAME || warning "Не удалось получить конфигурацию сервиса"

echo ""
log "8️⃣ Рекомендации по исправлению..."

# Даем рекомендации
if ! sudo systemctl list-unit-files | grep -q "$SERVICE_NAME.service"; then
    log "🔧 Рекомендация: Создайте сервис"
    echo "  sudo cp $PROJECT_DIR/deploy/websocket-server.service /etc/systemd/system/"
    echo "  sudo systemctl daemon-reload"
    echo "  sudo systemctl enable $SERVICE_NAME"
fi

if [ ! -f "$PROJECT_DIR/server/websocket-server" ]; then
    log "🔧 Рекомендация: Соберите проект"
    echo "  cd $PROJECT_DIR/server"
    echo "  go mod tidy"
    echo "  go build -o websocket-server main.go"
    echo "  sudo chown www-data:www-data websocket-server"
    echo "  sudo chmod +x websocket-server"
fi

if ! [[ "$BINARY_PERMS" == *"x"* ]]; then
    log "🔧 Рекомендация: Сделайте файл исполняемым"
    echo "  sudo chmod +x $PROJECT_DIR/server/websocket-server"
fi

if [ "$BINARY_OWNER" != "www-data:www-data" ]; then
    log "🔧 Рекомендация: Установите правильного владельца"
    echo "  sudo chown www-data:www-data $PROJECT_DIR/server/websocket-server"
fi

if sudo netstat -tlnp | grep -q ":9092"; then
    log "🔧 Рекомендация: Освободите порт 9092"
    echo "  sudo pkill -f websocket-server"
    echo "  sudo systemctl stop $SERVICE_NAME"
fi

echo ""
log "🎯 Диагностика завершена!"
log "📋 Для исправления проблем используйте рекомендации выше"
