#!/bin/bash

# Скрипт обновления Go на сервере
# Использование: ./update-go.sh [версия]

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

show_help() {
    echo "Обновление Go на сервере"
    echo ""
    echo "Использование: $0 [версия]"
    echo ""
    echo "Примеры:"
    echo "  $0              # Обновить до последней версии 1.21.x"
    echo "  $0 1.21.5       # Обновить до конкретной версии"
    echo "  $0 1.22.0       # Обновить до версии 1.22.0"
    echo ""
    echo "Доступные версии:"
    echo "  1.21.5, 1.21.4, 1.21.3, 1.21.2, 1.21.1, 1.21.0"
    echo "  1.22.0, 1.22.1, 1.22.2"
}

# Определяем версию для установки
if [ -z "$1" ]; then
    GO_VERSION="1.21.5"
else
    GO_VERSION="$1"
fi

log "🔄 Обновление Go до версии $GO_VERSION..."

# Проверяем текущую версию Go
if command -v go &> /dev/null; then
    CURRENT_VERSION=$(go version | grep -o 'go[0-9]\+\.[0-9]\+\.[0-9]\+' | sed 's/go//')
    log "📋 Текущая версия Go: $CURRENT_VERSION"
    
    if [ "$CURRENT_VERSION" = "$GO_VERSION" ]; then
        log "✅ Go уже обновлен до версии $GO_VERSION"
        exit 0
    fi
else
    warning "⚠️  Go не установлен"
fi

# Удаляем старую версию Go
if [ -d "/usr/local/go" ]; then
    log "🗑️  Удаляем старую версию Go..."
    sudo rm -rf /usr/local/go
fi

# Удаляем старые версии из PATH
log "🧹 Очищаем PATH от старых версий Go..."
sudo sed -i '/\/usr\/local\/go\/bin/d' /etc/profile
sudo sed -i '/\/usr\/lib\/go-1\./d' /etc/profile

# Скачиваем новую версию Go
log "📥 Скачиваем Go $GO_VERSION..."
GO_FILE="go${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/${GO_FILE}"

if [ -f "$GO_FILE" ]; then
    rm -f "$GO_FILE"
fi

wget -q "$GO_URL" || error "Не удалось скачать Go $GO_VERSION"

# Устанавливаем новую версию
log "🔧 Устанавливаем Go $GO_VERSION..."
sudo tar -C /usr/local -xzf "$GO_FILE"

# Обновляем PATH
log "🔗 Обновляем PATH..."
export PATH=$PATH:/usr/local/go/bin

# Добавляем в профиль (если еще не добавлено)
if ! grep -q "/usr/local/go/bin" /etc/profile; then
    echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile
    log "✅ PATH добавлен в /etc/profile"
fi

# Проверяем установку
log "🧪 Проверяем установку..."
sleep 2  # Даем время системе обновиться

# Обновляем PATH для текущей сессии
export PATH=$PATH:/usr/local/go/bin

# Проверяем версию
NEW_VERSION=$(/usr/local/go/bin/go version 2>/dev/null | grep -o 'go[0-9]\+\.[0-9]\+\.[0-9]\+' | sed 's/go//' || echo "unknown")

if [ "$NEW_VERSION" = "$GO_VERSION" ]; then
    log "✅ Go успешно обновлен до версии $NEW_VERSION"
elif [ "$NEW_VERSION" != "unknown" ]; then
    warning "⚠️  Установлена версия $NEW_VERSION вместо $GO_VERSION"
    log "🔍 Проверяем доступность Go..."
    
    # Проверяем, работает ли Go
    if /usr/local/go/bin/go version >/dev/null 2>&1; then
        log "✅ Go работает корректно, версия: $NEW_VERSION"
    else
        error "❌ Go не работает после установки"
    fi
else
    error "❌ Не удалось определить версию Go после установки"
fi

# Очищаем временные файлы
rm -f "$GO_FILE"

# Проверяем работоспособность
log "🔍 Проверяем работоспособность..."
go version
go env GOROOT
go env GOPATH

log "🎉 Обновление Go завершено успешно!"
log "📋 Новая версия: $NEW_VERSION"
log "📍 Расположение: /usr/local/go"
log "🔗 PATH обновлен"

echo ""
log "Полезные команды:"
echo "  go version                    # Версия Go"
echo "  go env                        # Переменные окружения"
echo "  go mod tidy                   # Очистка зависимостей"
echo "  go build -o app main.go       # Сборка приложения"
