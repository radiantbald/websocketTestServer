#!/bin/bash

# Принудительное обновление Go на сервере
# Использование: ./force-update-go.sh

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

GO_VERSION="1.21.5"

log "🚀 Принудительное обновление Go до версии $GO_VERSION..."

# Останавливаем все процессы, использующие Go
log "⏹️  Останавливаем процессы, использующие Go..."
sudo pkill -f "go run" || true
sudo pkill -f "websocket-server" || true

# Удаляем все версии Go
log "🗑️  Удаляем все версии Go..."
sudo rm -rf /usr/local/go
sudo rm -rf /usr/lib/go-*
sudo rm -rf /usr/share/go
sudo apt remove -y golang-go || true

# Очищаем PATH
log "🧹 Очищаем PATH..."
sudo sed -i '/\/usr\/local\/go\/bin/d' /etc/profile
sudo sed -i '/\/usr\/lib\/go-1\./d' /etc/profile
sudo sed -i '/\/usr\/share\/go\/bin/d' /etc/profile

# Очищаем переменные окружения
unset GOROOT
unset GOPATH
unset PATH

# Восстанавливаем базовый PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Скачиваем и устанавливаем Go
log "📥 Скачиваем Go $GO_VERSION..."
GO_FILE="go${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/${GO_FILE}"

cd /tmp
rm -f "$GO_FILE"
wget -q "$GO_URL" || error "Не удалось скачать Go $GO_VERSION"

# Устанавливаем Go
log "🔧 Устанавливаем Go $GO_VERSION..."
sudo tar -C /usr/local -xzf "$GO_FILE"

# Настраиваем PATH
log "🔗 Настраиваем PATH..."
export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile

# Проверяем установку
log "🧪 Проверяем установку..."
sleep 3

# Проверяем версию
NEW_VERSION=$(/usr/local/go/bin/go version 2>/dev/null | grep -o 'go[0-9]\+\.[0-9]\+\.[0-9]\+' | sed 's/go//' || echo "unknown")

if [ "$NEW_VERSION" = "$GO_VERSION" ]; then
    log "✅ Go успешно обновлен до версии $NEW_VERSION"
elif [ "$NEW_VERSION" != "unknown" ]; then
    log "✅ Go установлен, версия: $NEW_VERSION"
else
    error "❌ Не удалось установить Go"
fi

# Очищаем временные файлы
rm -f "$GO_FILE"

# Проверяем работоспособность
log "🔍 Проверяем работоспособность..."
/usr/local/go/bin/go version
/usr/local/go/bin/go env GOROOT

log "🎉 Принудительное обновление Go завершено!"
log "📋 Установленная версия: $NEW_VERSION"
log "📍 Расположение: /usr/local/go"

echo ""
log "⚠️  ВАЖНО: Перезайдите в терминал или выполните:"
echo "  source /etc/profile"
echo "  export PATH=\$PATH:/usr/local/go/bin"
echo ""
log "Затем проверьте:"
echo "  go version"
echo "  which go"
