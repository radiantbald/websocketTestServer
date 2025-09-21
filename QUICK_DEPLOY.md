# 🚀 Быстрый деплой на qabase.ru

## 📋 Порядок деплоя (15-20 минут)

### 1. Подготовка сервера
```bash
# Подключитесь к серверу Timeweb
ssh root@your-server-ip

# Обновите систему и установите пакеты
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx certbot python3-certbot-nginx golang-go git
```

### 2. Загрузка проекта
```bash
# Создайте директорию и загрузите проект
sudo mkdir -p /var/www/qabase
cd /var/www/qabase

# Клонируйте из GitHub
sudo git clone https://github.com/radiantbald/websocketTestServer.git .

# Установите права
sudo chown -R www-data:www-data /var/www/qabase
sudo chmod +x /var/www/qabase/deploy/*.sh
```

### 3. Сборка приложения
```bash
# Соберите Go приложение
cd /var/www/qabase/server
go mod tidy
go build -o websocket-server main.go
sudo chown www-data:www-data websocket-server
sudo chmod +x websocket-server
```

### 4. Настройка systemd
```bash
# Настройте автозапуск
sudo cp /var/www/qabase/deploy/websocket-server.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable websocket-server
sudo systemctl start websocket-server
```

### 5. Настройка nginx
```bash
# Настройте nginx
sudo rm -f /etc/nginx/sites-enabled/default
sudo cp /var/www/qabase/deploy/nginx-qabase.conf /etc/nginx/sites-available/qabase.ru
sudo ln -s /etc/nginx/sites-available/qabase.ru /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 6. SSL сертификаты
```bash
# Получите SSL сертификат
sudo certbot --nginx -d qabase.ru -d www.qabase.ru --non-interactive --agree-tos --email admin@qabase.ru

# Настройте автообновление
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

### 7. Проверка
```bash
# Проверяем статус
cd /var/www/qabase
./deploy/manage.sh status

# Тестируем соединение
./deploy/manage.sh test

# Проверяем в браузере
curl -f https://qabase.ru/status
```

## ✅ Готово!

Ваш WebSocket сервер доступен по адресам:
- **Сайт**: https://qabase.ru
- **WebSocket**: wss://qabase.ru/websocket
- **Статус**: https://qabase.ru/status

## 🛠️ Управление

```bash
# Полезные команды
make help           # Справка
make status         # Статус сервера
make logs           # Логи
make restart        # Перезапуск
make backup         # Резервная копия
```

## 📚 Подробная документация

См. [DEPLOY_QABASE.md](DEPLOY_QABASE.md) для детальной информации.
