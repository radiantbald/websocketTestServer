# 🚀 Шпаргалка деплоя qabase.ru

## ⚡ Быстрые команды (копируй-вставляй)

### 1. Подготовка
```bash
ssh root@your-server-ip
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx certbot python3-certbot-nginx golang-go git
```

### 2. Загрузка проекта
```bash
sudo mkdir -p /var/www/qabase
cd /var/www/qabase
sudo git clone https://github.com/radiantbald/websocketTestServer.git .
sudo chown -R www-data:www-data /var/www/qabase
sudo chmod +x /var/www/qabase/deploy/*.sh
```

### 3. Сборка
```bash
cd /var/www/qabase/server
go mod tidy
go build -o websocket-server main.go
sudo chown www-data:www-data websocket-server
sudo chmod +x websocket-server
```

### 4. Systemd
```bash
sudo cp /var/www/qabase/deploy/websocket-server.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable websocket-server
sudo systemctl start websocket-server
```

### 5. Nginx
```bash
sudo rm -f /etc/nginx/sites-enabled/default
sudo cp /var/www/qabase/deploy/nginx-qabase.conf /etc/nginx/sites-available/qabase.ru
sudo ln -s /etc/nginx/sites-available/qabase.ru /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx
```

### 6. SSL
```bash
sudo certbot --nginx -d qabase.ru -d www.qabase.ru --non-interactive --agree-tos --email admin@qabase.ru
sudo systemctl enable certbot.timer && sudo systemctl start certbot.timer
```

### 7. Проверка
```bash
cd /var/www/qabase
./deploy/manage.sh status
./deploy/manage.sh test
curl -f https://qabase.ru/status
```

## 🔍 Диагностика

### Проверка сервисов
```bash
sudo systemctl status websocket-server
sudo systemctl status nginx
sudo systemctl status certbot.timer
```

### Проверка портов
```bash
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
sudo netstat -tlnp | grep :9092
```

### Логи
```bash
sudo journalctl -u websocket-server -f
sudo tail -f /var/log/nginx/qabase.ru.access.log
sudo tail -f /var/log/nginx/qabase.ru.error.log
```

### Тест WebSocket
```bash
wscat -c wss://qabase.ru/ws?username=test
```

## 🚨 Быстрое исправление

### Если Go не работает
```bash
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
```

### Если nginx не запускается
```bash
sudo nginx -t
sudo tail -f /var/log/nginx/error.log
```

### Если сервер не запускается
```bash
sudo journalctl -u websocket-server -f
cd /var/www/qabase/server
sudo -u www-data ./websocket-server
```

## 📊 Результат
- **Сайт**: https://qabase.ru
- **WebSocket**: wss://qabase.ru/ws
- **Статус**: https://qabase.ru/status
