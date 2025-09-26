#!/bin/bash

# Скрипт для обновления и управления WebSocket сервером
# Использование: ./update-server.sh [команда]

set -e  # Остановка при ошибке

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')]${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

# Функция помощи
show_help() {
    echo "WebSocket Server Management Script"
    echo ""
    echo "Использование: $0 [команда]"
    echo ""
    echo "Команды:"
    echo "  update     - Обновить код и перезапустить сервер"
    echo "  build      - Пересобрать Go сервер"
    echo "  restart    - Перезапустить сервер"
    echo "  status     - Показать статус сервера"
    echo "  logs       - Показать логи сервера"
    echo "  stop       - Остановить сервер"
    echo "  start      - Запустить сервер"
    echo "  deploy     - Полное развертывание (обновление + перезапуск)"
    echo "  help       - Показать эту справку"
    echo ""
    echo "Примеры:"
    echo "  $0 update"
    echo "  $0 deploy"
    echo "  $0 status"
}

# Функция обновления кода
update_code() {
    log "🔄 Обновляем код из репозитория..."
    if [ -d ".git" ]; then
        git pull origin main
        log "✅ Код обновлен"
    else
        warn "⚠️  Не найден git репозиторий, пропускаем обновление кода"
    fi
}

# Функция сборки сервера
build_server() {
    log "🔨 Пересобираем Go сервер..."
    cd server
    go mod tidy
    go build -o websocket-server main.go
    cd ..
    log "✅ Сервер пересобран"
}

# Функция перезапуска сервера
restart_server() {
    log "🔄 Перезапускаем сервер..."
    
    # Проверяем, запущен ли сервер как systemd сервис
    if systemctl is-active --quiet websocket-server 2>/dev/null; then
        log "🔄 Перезапускаем systemd сервис..."
        systemctl restart websocket-server
        log "✅ Systemd сервис перезапущен"
    else
        # Если не systemd, ищем процесс и перезапускаем
        if pgrep -f "websocket-server" > /dev/null; then
            log "🔄 Останавливаем существующий процесс..."
            pkill -f "websocket-server" || true
            sleep 2
        fi
        
        log "🚀 Запускаем сервер в фоне..."
        cd server
        nohup ./websocket-server > ../server.log 2>&1 &
        cd ..
        log "✅ Сервер запущен в фоне"
    fi
}

# Функция проверки статуса
check_status() {
    log "📊 Проверяем статус сервера..."
    
    # Проверяем systemd сервис
    if systemctl is-active --quiet websocket-server 2>/dev/null; then
        info "Systemd сервис:"
        systemctl status websocket-server --no-pager
    else
        # Проверяем процесс
        if pgrep -f "websocket-server" > /dev/null; then
            info "Процесс сервера запущен:"
            ps aux | grep websocket-server | grep -v grep
        else
            warn "⚠️  Сервер не запущен"
        fi
    fi
    
    # Проверяем доступность
    if curl -s http://localhost:9092/status > /dev/null 2>&1; then
        log "✅ Сервер отвечает на http://localhost:9092/status"
    else
        warn "⚠️  Сервер не отвечает на localhost:9092"
    fi
}

# Функция показа логов
show_logs() {
    log "📋 Показываем логи сервера..."
    
    if systemctl is-active --quiet websocket-server 2>/dev/null; then
        info "Логи systemd сервиса:"
        journalctl -u websocket-server -n 20 --no-pager
    else
        if [ -f "server.log" ]; then
            info "Логи сервера:"
            tail -20 server.log
        else
            warn "⚠️  Файл логов не найден"
        fi
    fi
}

# Функция остановки сервера
stop_server() {
    log "🛑 Останавливаем сервер..."
    
    if systemctl is-active --quiet websocket-server 2>/dev/null; then
        systemctl stop websocket-server
        log "✅ Systemd сервис остановлен"
    else
        if pgrep -f "websocket-server" > /dev/null; then
            pkill -f "websocket-server"
            log "✅ Процесс сервера остановлен"
        else
            warn "⚠️  Сервер не был запущен"
        fi
    fi
}

# Функция запуска сервера
start_server() {
    log "🚀 Запускаем сервер..."
    
    if systemctl is-active --quiet websocket-server 2>/dev/null; then
        log "✅ Systemd сервис уже запущен"
    else
        if systemctl list-unit-files | grep -q websocket-server; then
            systemctl start websocket-server
            log "✅ Systemd сервис запущен"
        else
            # Запускаем в фоне
            cd server
            nohup ./websocket-server > ../server.log 2>&1 &
            cd ..
            log "✅ Сервер запущен в фоне"
        fi
    fi
}

# Функция полного развертывания
deploy() {
    log "🚀 Начинаем полное развертывание..."
    update_code
    build_server
    restart_server
    sleep 3
    check_status
    log "✅ Развертывание завершено"
}

# Основная логика
case "${1:-help}" in
    "update")
        update_code
        build_server
        restart_server
        ;;
    "build")
        build_server
        ;;
    "restart")
        restart_server
        ;;
    "status")
        check_status
        ;;
    "logs")
        show_logs
        ;;
    "stop")
        stop_server
        ;;
    "start")
        start_server
        ;;
    "deploy")
        deploy
        ;;
    "help"|*)
        show_help
        ;;
esac
