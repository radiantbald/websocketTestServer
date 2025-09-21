# 🔄 Шпаргалка обновления проекта

## ⚡ Быстрые команды

### Обычное обновление
```bash
cd /var/www/qabase
./deploy/update.sh
```

### Быстрое обновление (без резервной копии)
```bash
cd /var/www/qabase
./deploy/update.sh --no-backup
```

### Только резервная копия
```bash
cd /var/www/qabase
./deploy/update.sh --backup-only
```

### Принудительное обновление
```bash
cd /var/www/qabase
./deploy/update.sh --force
```

## 🔧 Ручное обновление

### Git Pull метод
```bash
cd /var/www/qabase
git stash
git pull origin main
git stash pop
cd server
go mod tidy
go build -o websocket-server main.go
sudo chown www-data:www-data websocket-server
sudo systemctl restart websocket-server
```

### Настройка сервиса
```bash
# Создать/обновить systemd сервис
./deploy/setup-service.sh

# Показать статус сервиса
./deploy/setup-service.sh --status

# Перезапустить сервис
./deploy/setup-service.sh --restart

# Удалить сервис
./deploy/setup-service.sh --remove
```

### Полная переустановка
```bash
sudo systemctl stop websocket-server
sudo mv /var/www/qabase /var/www/qabase.old
cd /var/www
sudo git clone https://github.com/radiantbald/websocketTestServer.git qabase
sudo chown -R www-data:www-data /var/www/qabase
cd /var/www/qabase/server
go mod tidy
go build -o websocket-server main.go
sudo chown www-data:www-data websocket-server
sudo systemctl start websocket-server
```

## 🔍 Проверка обновления

### Автоматическая проверка
```bash
./deploy/manage.sh status
./deploy/manage.sh test
```

### Ручная проверка
```bash
sudo systemctl status websocket-server
curl -f https://qabase.ru/status
wscat -c wss://qabase.ru/ws?username=test
```

## 🚨 Восстановление

### Из резервной копии
```bash
sudo systemctl stop websocket-server
sudo tar -xzf /var/backups/qabase-backup-YYYYMMDD-HHMMSS.tar.gz -C /
sudo systemctl start websocket-server
```

### Откат git
```bash
cd /var/www/qabase
git reset --hard HEAD~1
cd server
go build -o websocket-server main.go
sudo systemctl restart websocket-server
```

## 🔧 Исправление проблем

### Проблема с версией Go
```bash
# Ошибка: "go.mod file indicates go 1.21, but maximum version supported by tidy is 1.18"

# Решение 1: Обычное обновление
./deploy/update-go.sh

# Решение 2: Принудительное обновление (если обычное не работает)
./deploy/force-update-go.sh

# Решение 3: Ручное обновление
sudo rm -rf /usr/local/go
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile
source /etc/profile
go version
```

## 📊 Мониторинг

### Логи
```bash
sudo journalctl -u websocket-server -f
sudo tail -f /var/log/nginx/qabase.ru.access.log
```

### Статус
```bash
sudo systemctl status websocket-server
sudo netstat -tlnp | grep :9092
```

## 🎯 Рекомендации

1. **Всегда** создавайте резервную копию
2. **Обновляйте** в нерабочее время
3. **Тестируйте** после обновления
4. **Мониторьте** логи
5. **Имейте** план отката
