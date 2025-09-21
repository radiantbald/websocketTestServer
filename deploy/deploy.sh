#!/bin/bash

# Скрипт деплоя WebSocket сервера на qabase.ru
# Использование: ./deploy.sh

set -e

echo "🚀 Начинаем деплой WebSocket сервера на qabase.ru..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для логирования
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

# Проверяем, что мы в правильной директории
if [ ! -f "server/main.go" ]; then
    error "Запустите скрипт из корневой директории проекта"
fi

# Переменные
PROJECT_DIR="/var/www/qabase"
SERVER_DIR="$PROJECT_DIR/server"
CLIENT_DIR="$PROJECT_DIR/client"
SERVICE_NAME="websocket-server"
NGINX_SITE="qabase.ru"

log "Создаем директории..."
sudo mkdir -p $PROJECT_DIR
sudo mkdir -p $SERVER_DIR
sudo mkdir -p $CLIENT_DIR

log "Копируем файлы сервера..."
sudo cp -r server/* $SERVER_DIR/
sudo cp -r client/* $CLIENT_DIR/

log "Устанавливаем права доступа..."
sudo chown -R www-data:www-data $PROJECT_DIR
sudo chmod -R 755 $PROJECT_DIR

log "Собираем Go приложение..."
cd $SERVER_DIR
sudo -u www-data go mod tidy
sudo -u www-data go build -o websocket-server main.go

log "Копируем systemd service..."
sudo cp deploy/websocket-server.service /etc/systemd/system/
sudo systemctl daemon-reload

log "Копируем nginx конфигурацию..."
sudo cp deploy/nginx-qabase.conf /etc/nginx/sites-available/$NGINX_SITE
sudo ln -sf /etc/nginx/sites-available/$NGINX_SITE /etc/nginx/sites-enabled/

log "Проверяем nginx конфигурацию..."
sudo nginx -t || error "Ошибка в конфигурации nginx"

log "Перезапускаем nginx..."
sudo systemctl reload nginx

log "Запускаем WebSocket сервер..."
sudo systemctl enable $SERVICE_NAME
sudo systemctl restart $SERVICE_NAME

log "Проверяем статус сервиса..."
sleep 2
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    log "✅ Сервис успешно запущен"
else
    error "❌ Ошибка запуска сервиса"
fi

log "Проверяем доступность сервера..."
sleep 3
if curl -f -s http://localhost:9092/status > /dev/null; then
    log "✅ Сервер отвечает на localhost:9092"
else
    warning "⚠️  Сервер не отвечает на localhost:9092"
fi

log "🎉 Деплой завершен успешно!"
log "Сервер доступен по адресу: https://qabase.ru"
log "WebSocket endpoint: wss://qabase.ru/websocket"
log "Статус: https://qabase.ru/status"

echo ""
log "Полезные команды:"
echo "  sudo systemctl status $SERVICE_NAME    # Статус сервиса"
echo "  sudo systemctl restart $SERVICE_NAME   # Перезапуск сервиса"
echo "  sudo journalctl -u $SERVICE_NAME -f    # Логи сервиса"
echo "  sudo nginx -t                          # Проверка nginx"
echo "  sudo systemctl reload nginx            # Перезагрузка nginx"
