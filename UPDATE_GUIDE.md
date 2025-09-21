# 🔄 Обновление проекта на хостинге из GitHub

## 🎯 Цель
Правильно обновлять код на сервере qabase.ru при изменениях в GitHub репозитории.

## ⚠️ Важно
- **НЕ** обновляйте код во время работы пользователей
- **ВСЕГДА** создавайте резервную копию перед обновлением
- **ПРОВЕРЯЙТЕ** каждый этап перед переходом к следующему

---

## 📋 МЕТОДЫ ОБНОВЛЕНИЯ

### 🔄 Метод 1: Git Pull (Рекомендуемый)

#### Шаг 1: Подключение к серверу
```bash
ssh root@your-server-ip
cd /var/www/qabase
```

#### Шаг 2: Создание резервной копии
```bash
# Создайте резервную копию
./deploy/manage.sh backup

# Или вручную
sudo tar -czf /var/backups/qabase-backup-$(date +%Y%m%d-%H%M%S).tar.gz \
    -C /var/www qabase \
    -C /etc/nginx/sites-available qabase.ru \
    -C /etc/systemd/system websocket-server.service
```

#### Шаг 3: Остановка сервисов
```bash
# Остановите WebSocket сервер
sudo systemctl stop websocket-server

# Остановите nginx (опционально, для безопасности)
sudo systemctl stop nginx
```

#### Шаг 4: Обновление кода
```bash
# Перейдите в директорию проекта
cd /var/www/qabase

# Сохраните локальные изменения (если есть)
git stash

# Получите последние изменения
git fetch origin
git pull origin main

# Восстановите локальные изменения (если нужно)
git stash pop
```

#### Шаг 5: Обновление зависимостей и сборка
```bash
# Обновите Go зависимости
cd /var/www/qabase/server
go mod tidy
go mod download

# Пересоберите приложение
go build -o websocket-server main.go

# Установите права
sudo chown www-data:www-data websocket-server
sudo chmod +x websocket-server
```

#### Шаг 6: Обновление конфигураций
```bash
# Обновите systemd service (если изменился)
sudo cp /var/www/qabase/deploy/websocket-server.service /etc/systemd/system/
sudo systemctl daemon-reload

# Обновите nginx конфигурацию (если изменилась)
sudo cp /var/www/qabase/deploy/nginx-qabase.conf /etc/nginx/sites-available/qabase.ru
sudo nginx -t
```

#### Шаг 7: Запуск сервисов
```bash
# Запустите WebSocket сервер
sudo systemctl start websocket-server

# Запустите nginx
sudo systemctl start nginx

# Проверьте статус
sudo systemctl status websocket-server
sudo systemctl status nginx
```

#### Шаг 8: Проверка работы
```bash
# Проверьте статус
./deploy/manage.sh status

# Тестируйте соединение
./deploy/manage.sh test

# Проверьте в браузере
curl -f https://qabase.ru/status
```

---

### 🔄 Метод 2: Полная переустановка

#### Когда использовать:
- При серьезных изменениях в структуре проекта
- При проблемах с git pull
- При изменении зависимостей

#### Шаг 1: Резервная копия
```bash
./deploy/manage.sh backup
```

#### Шаг 2: Остановка сервисов
```bash
sudo systemctl stop websocket-server
sudo systemctl stop nginx
```

#### Шаг 3: Удаление старой версии
```bash
# Удалите старую версию (сохраните конфигурации)
sudo mv /var/www/qabase /var/www/qabase.old
```

#### Шаг 4: Клонирование новой версии
```bash
# Клонируйте новую версию
cd /var/www
sudo git clone https://github.com/radiantbald/websocketTestServer.git qabase

# Установите права
sudo chown -R www-data:www-data /var/www/qabase
sudo chmod +x /var/www/qabase/deploy/*.sh
```

#### Шаг 5: Сборка и настройка
```bash
# Соберите приложение
cd /var/www/qabase/server
go mod tidy
go build -o websocket-server main.go
sudo chown www-data:www-data websocket-server
sudo chmod +x websocket-server

# Настройте systemd
sudo cp /var/www/qabase/deploy/websocket-server.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable websocket-server

# Настройте nginx
sudo cp /var/www/qabase/deploy/nginx-qabase.conf /etc/nginx/sites-available/qabase.ru
sudo nginx -t
```

#### Шаг 6: Запуск
```bash
sudo systemctl start websocket-server
sudo systemctl start nginx
```

---

## 🚀 АВТОМАТИЧЕСКОЕ ОБНОВЛЕНИЕ

### Создание скрипта автообновления

#### Шаг 1: Создайте скрипт обновления
```bash
sudo nano /var/www/qabase/deploy/update.sh
```

#### Шаг 2: Содержимое скрипта
```bash
#!/bin/bash

# Скрипт автоматического обновления
set -e

PROJECT_DIR="/var/www/qabase"
SERVICE_NAME="websocket-server"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

log "Начинаем обновление проекта..."

# Создаем резервную копию
log "Создаем резервную копию..."
./deploy/manage.sh backup

# Останавливаем сервисы
log "Останавливаем сервисы..."
sudo systemctl stop $SERVICE_NAME

# Обновляем код
log "Обновляем код из GitHub..."
cd $PROJECT_DIR
git fetch origin
git pull origin main

# Пересобираем приложение
log "Пересобираем приложение..."
cd $PROJECT_DIR/server
go mod tidy
go build -o websocket-server main.go
sudo chown www-data:www-data websocket-server
sudo chmod +x websocket-server

# Обновляем конфигурации
log "Обновляем конфигурации..."
sudo cp $PROJECT_DIR/deploy/websocket-server.service /etc/systemd/system/
sudo systemctl daemon-reload

sudo cp $PROJECT_DIR/deploy/nginx-qabase.conf /etc/nginx/sites-available/qabase.ru
sudo nginx -t

# Запускаем сервисы
log "Запускаем сервисы..."
sudo systemctl start $SERVICE_NAME
sudo systemctl reload nginx

# Проверяем статус
log "Проверяем статус..."
sleep 3
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    log "✅ Обновление завершено успешно"
else
    error "❌ Ошибка при запуске сервиса"
fi

log "🎉 Проект обновлен!"
```

#### Шаг 3: Сделайте скрипт исполняемым
```bash
sudo chmod +x /var/www/qabase/deploy/update.sh
```

#### Шаг 4: Использование
```bash
cd /var/www/qabase
./deploy/update.sh
```

---

## 🔍 ПРОВЕРКА ОБНОВЛЕНИЯ

### Автоматическая проверка
```bash
# Используйте встроенный скрипт
./deploy/manage.sh status
./deploy/manage.sh test
```

### Ручная проверка
```bash
# Проверьте статус сервисов
sudo systemctl status websocket-server
sudo systemctl status nginx

# Проверьте порты
sudo netstat -tlnp | grep :9092
sudo netstat -tlnp | grep :443

# Проверьте логи
sudo journalctl -u websocket-server -n 20

# Тест HTTP
curl -f https://qabase.ru/status

# Тест WebSocket
wscat -c wss://qabase.ru/ws?username=test
```

---

## 🚨 УСТРАНЕНИЕ ПРОБЛЕМ

### Если обновление не удалось
```bash
# Восстановите из резервной копии
sudo systemctl stop websocket-server
sudo systemctl stop nginx

# Найдите последнюю резервную копию
ls -la /var/backups/qabase-backup-*

# Восстановите
sudo tar -xzf /var/backups/qabase-backup-YYYYMMDD-HHMMSS.tar.gz -C /

# Запустите сервисы
sudo systemctl start websocket-server
sudo systemctl start nginx
```

### Если есть конфликты в git
```bash
# Сбросьте изменения
git reset --hard HEAD
git clean -fd

# Получите последнюю версию
git pull origin main
```

### Если не собирается Go приложение
```bash
# Очистите кэш модулей
go clean -modcache
go mod download

# Пересоберите
go build -o websocket-server main.go
```

---

## 📊 МОНИТОРИНГ ОБНОВЛЕНИЙ

### Настройка уведомлений
```bash
# Добавьте в скрипт обновления отправку уведомлений
# Например, через email или Telegram
```

### Логирование обновлений
```bash
# Все обновления логируются в systemd journal
sudo journalctl -u websocket-server -f
```

---

## 🎯 РЕКОМЕНДАЦИИ

### Лучшие практики:
1. **Всегда** создавайте резервную копию
2. **Тестируйте** обновления на тестовом сервере
3. **Обновляйте** в нерабочее время
4. **Мониторьте** логи после обновления
5. **Имейте** план отката

### Частота обновлений:
- **Критические исправления**: немедленно
- **Новые функции**: еженедельно
- **Обновления зависимостей**: ежемесячно

---

## 📞 Поддержка

При проблемах с обновлением:
1. Проверьте логи: `sudo journalctl -u websocket-server -f`
2. Восстановите из резервной копии
3. Используйте метод полной переустановки
4. Обратитесь к документации проекта
