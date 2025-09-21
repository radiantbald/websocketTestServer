# Деплой WebSocket сервера на qabase.ru (Timeweb)

## 📋 Обзор

Этот документ описывает процесс деплоя WebSocket тестового сервера на домен qabase.ru, размещенный на хостинге Timeweb.

## 🎯 Цели деплоя

- Развернуть WebSocket сервер на домене qabase.ru
- Настроить HTTPS/WSS соединения
- Обеспечить автозапуск и мониторинг
- Настроить nginx для проксирования
- Создать систему управления сервером

## 🏗️ Архитектура

```
Internet → nginx (443/80) → Go WebSocket Server (9092)
         ↓
    Static Files (HTML/CSS/JS)
```

## 📁 Структура файлов на сервере

```
/var/www/qabase/
├── server/
│   ├── main.go
│   ├── go.mod
│   ├── go.sum
│   └── websocket-server (бинарный файл)
├── client/
│   ├── test-client.html
│   └── websocket-test.html
└── logs/
    └── websocket-server.log
```

## 🚀 Быстрый старт

### 1. Подготовка сервера

```bash
# Обновляем систему
sudo apt update && sudo apt upgrade -y

# Устанавливаем необходимые пакеты
sudo apt install -y nginx certbot python3-certbot-nginx golang-go

# Создаем пользователя для веб-сервера
sudo useradd -r -s /bin/false www-data
```

### 2. Загрузка проекта

```bash
# Клонируем или загружаем проект
cd /var/www
sudo git clone <your-repo-url> qabase
# или
sudo scp -r /path/to/websocket-test-server qabase

# Устанавливаем права
sudo chown -R www-data:www-data /var/www/qabase
sudo chmod -R 755 /var/www/qabase
```

### 3. Автоматический деплой

```bash
cd /var/www/qabase
sudo ./deploy/deploy.sh
```

### 4. Настройка SSL

```bash
sudo ./deploy/ssl-setup.sh
```

## 🔧 Ручная настройка

### 1. Сборка Go приложения

```bash
cd /var/www/qabase/server
sudo -u www-data go mod tidy
sudo -u www-data go build -o websocket-server main.go
```

### 2. Настройка systemd

```bash
# Копируем service файл
sudo cp deploy/websocket-server.service /etc/systemd/system/

# Перезагружаем systemd
sudo systemctl daemon-reload

# Включаем автозапуск
sudo systemctl enable websocket-server

# Запускаем сервис
sudo systemctl start websocket-server
```

### 3. Настройка nginx

```bash
# Копируем конфигурацию
sudo cp deploy/nginx-qabase.conf /etc/nginx/sites-available/qabase.ru

# Включаем сайт
sudo ln -s /etc/nginx/sites-available/qabase.ru /etc/nginx/sites-enabled/

# Проверяем конфигурацию
sudo nginx -t

# Перезагружаем nginx
sudo systemctl reload nginx
```

### 4. Настройка SSL с Let's Encrypt

```bash
# Получаем сертификат
sudo certbot --nginx -d qabase.ru -d www.qabase.ru

# Настраиваем автообновление
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

## 🛠️ Управление сервером

### Использование Makefile

```bash
# Показать справку
make help

# Собрать проект
make build

# Запустить локально
make run

# Деплой на сервер
make deploy

# Настройка SSL
make ssl-setup

# Управление сервисом
make start      # Запустить
make stop       # Остановить
make restart    # Перезапустить
make status     # Статус
make logs       # Логи
make update     # Обновить код
make backup     # Резервная копия
```

### Использование скриптов напрямую

```bash
# Управление сервисом
./deploy/manage.sh start
./deploy/manage.sh stop
./deploy/manage.sh restart
./deploy/manage.sh status
./deploy/manage.sh logs
./deploy/manage.sh update
./deploy/manage.sh test
./deploy/manage.sh backup
```

## 🔍 Мониторинг и логи

### Просмотр логов

```bash
# Логи systemd
sudo journalctl -u websocket-server -f

# Логи nginx
sudo tail -f /var/log/nginx/qabase.ru.access.log
sudo tail -f /var/log/nginx/qabase.ru.error.log

# Логи приложения (если настроены)
sudo tail -f /var/log/websocket-server/websocket-server.log
```

### Проверка статуса

```bash
# Статус сервиса
sudo systemctl status websocket-server

# Проверка портов
sudo netstat -tlnp | grep :9092
sudo netstat -tlnp | grep :443

# Тест соединения
curl -f https://qabase.ru/status
```

## 🔒 Безопасность

### Настроенные меры безопасности

1. **CORS ограничения** - только разрешенные домены
2. **SSL/TLS** - принудительное HTTPS
3. **Заголовки безопасности** - HSTS, XSS защита, etc.
4. **Ограничения nginx** - rate limiting, размер запросов
5. **Изоляция процессов** - systemd security options
6. **Валидация входных данных** - проверка сообщений и имен пользователей

### Дополнительные рекомендации

```bash
# Настройка файрвола
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

# Регулярные обновления
sudo apt update && sudo apt upgrade -y

# Мониторинг ресурсов
htop
df -h
free -h
```

## 🚨 Устранение неполадок

### Сервер не запускается

```bash
# Проверяем логи
sudo journalctl -u websocket-server -n 50

# Проверяем конфигурацию
sudo systemctl cat websocket-server

# Проверяем права доступа
ls -la /var/www/qabase/server/websocket-server
```

### nginx ошибки

```bash
# Проверяем конфигурацию
sudo nginx -t

# Проверяем логи
sudo tail -f /var/log/nginx/error.log

# Проверяем статус
sudo systemctl status nginx
```

### SSL проблемы

```bash
# Проверяем сертификаты
sudo certbot certificates

# Тест обновления
sudo certbot renew --dry-run

# Проверяем срок действия
openssl x509 -in /etc/letsencrypt/live/qabase.ru/cert.pem -text -noout | grep "Not After"
```

### WebSocket не работает

```bash
# Проверяем проксирование
curl -I https://qabase.ru/websocket

# Тест WebSocket соединения
wscat -c wss://qabase.ru/websocket?username=test

# Проверяем nginx конфигурацию WebSocket
sudo nginx -T | grep -A 10 -B 5 "location /websocket"
```

## 📊 Производительность

### Мониторинг ресурсов

```bash
# Использование CPU и памяти
top -p $(pgrep websocket-server)

# Сетевые соединения
ss -tuln | grep :9092

# Логи производительности
sudo journalctl -u websocket-server --since "1 hour ago" | grep -i "performance\|slow\|timeout"
```

### Оптимизация

1. **Настройка Go runtime**:
   ```bash
   export GOMAXPROCS=2
   export GOGC=100
   ```

2. **Настройка nginx**:
   - Увеличить `worker_connections`
   - Настроить кэширование
   - Включить gzip сжатие

3. **Мониторинг соединений**:
   - Логирование количества активных соединений
   - Алерты при превышении лимитов

## 🔄 Обновление

### Обновление кода

```bash
# Автоматическое обновление
make update

# Или вручную
cd /var/www/qabase
sudo git pull origin main
sudo -u www-data go build -o server/websocket-server server/main.go
sudo systemctl restart websocket-server
```

### Обновление зависимостей

```bash
cd /var/www/qabase/server
sudo -u www-data go mod tidy
sudo -u www-data go mod download
sudo -u www-data go build -o websocket-server main.go
sudo systemctl restart websocket-server
```

## 📞 Поддержка

### Полезные команды

```bash
# Полная диагностика
./deploy/manage.sh test

# Создание резервной копии
./deploy/manage.sh backup

# Просмотр конфигурации
sudo systemctl cat websocket-server
sudo nginx -T | grep -A 20 "server_name qabase.ru"
```

### Контакты

- **Домен**: https://qabase.ru
- **WebSocket**: wss://qabase.ru/websocket
- **Статус**: https://qabase.ru/status
- **Логи**: `sudo journalctl -u websocket-server -f`

---

**Примечание**: Этот сервер предназначен для тестирования WebSocket соединений. Для продакшена рекомендуется добавить аутентификацию, авторизацию и дополнительные меры безопасности.
