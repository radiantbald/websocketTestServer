# 📋 Порядок деплоя WebSocket сервера на qabase.ru

## 🎯 Цель
Развернуть WebSocket тестовый сервер на домене qabase.ru с SSL сертификатами и автозапуском.

## ⚠️ Важно
- Выполняйте команды **последовательно**
- Не пропускайте шаги
- Проверяйте каждый этап перед переходом к следующему

---

## 📋 ПОДГОТОВКА СЕРВЕРА

### Шаг 1: Подключение к серверу
```bash
# Подключитесь к серверу Timeweb
ssh root@your-server-ip
# или
ssh username@your-server-ip
```

### Шаг 2: Обновление системы
```bash
# Обновите пакеты
sudo apt update && sudo apt upgrade -y

# Установите необходимые пакеты
sudo apt install -y nginx certbot python3-certbot-nginx golang-go git
```

### Шаг 3: Проверка Go
```bash
# Проверьте версию Go (должна быть 1.18+)
go version

# Если Go не установлен или старая версия:
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile
```

---

## 📁 ЗАГРУЗКА ПРОЕКТА

### Шаг 4: Загрузка кода
```bash
# Создайте директорию проекта
sudo mkdir -p /var/www/qabase
cd /var/www/qabase

# Вариант A: Клонирование из GitHub
sudo git clone https://github.com/radiantbald/websocketTestServer.git .

# Вариант B: Загрузка файлов через SCP
# scp -r /path/to/websocket-test-server/* root@server:/var/www/qabase/

# Установите права доступа
sudo chown -R www-data:www-data /var/www/qabase
sudo chmod -R 755 /var/www/qabase
```

### Шаг 5: Проверка файлов
```bash
# Убедитесь, что все файлы на месте
ls -la /var/www/qabase/
ls -la /var/www/qabase/deploy/
ls -la /var/www/qabase/server/
ls -la /var/www/qabase/client/
```

---

## 🔧 СБОРКА И НАСТРОЙКА

### Шаг 6: Сборка Go приложения
```bash
cd /var/www/qabase/server

# Соберите приложение
go mod tidy
go build -o websocket-server main.go

# Проверьте, что бинарный файл создан
ls -la websocket-server

# Установите права
sudo chown www-data:www-data websocket-server
sudo chmod +x websocket-server
```

### Шаг 7: Тест локального запуска
```bash
# Запустите сервер для тестирования
sudo -u www-data ./websocket-server

# В другом терминале проверьте:
curl -f http://localhost:9092/status

# Остановите тестовый сервер (Ctrl+C)
```

---

## ⚙️ НАСТРОЙКА SYSTEMD

### Шаг 8: Настройка автозапуска
```bash
# Скопируйте systemd service
sudo cp /var/www/qabase/deploy/websocket-server.service /etc/systemd/system/

# Перезагрузите systemd
sudo systemctl daemon-reload

# Включите автозапуск
sudo systemctl enable websocket-server

# Запустите сервис
sudo systemctl start websocket-server

# Проверьте статус
sudo systemctl status websocket-server
```

### Шаг 9: Проверка работы сервиса
```bash
# Проверьте, что сервер запущен
sudo systemctl is-active websocket-server

# Проверьте порт
sudo netstat -tlnp | grep :9092

# Проверьте логи
sudo journalctl -u websocket-server -n 20
```

---

## 🌐 НАСТРОЙКА NGINX

### Шаг 10: Настройка nginx
```bash
# Удалите дефолтную конфигурацию
sudo rm -f /etc/nginx/sites-enabled/default

# Скопируйте конфигурацию для qabase.ru
sudo cp /var/www/qabase/deploy/nginx-qabase.conf /etc/nginx/sites-available/qabase.ru

# Включите сайт
sudo ln -s /etc/nginx/sites-available/qabase.ru /etc/nginx/sites-enabled/

# Проверьте конфигурацию
sudo nginx -t
```

### Шаг 11: Запуск nginx
```bash
# Если тест прошел успешно, перезапустите nginx
sudo systemctl restart nginx

# Проверьте статус
sudo systemctl status nginx

# Проверьте порты
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
```

---

## 🔒 НАСТРОЙКА SSL

### Шаг 12: Получение SSL сертификата
```bash
# Получите SSL сертификат от Let's Encrypt
sudo certbot --nginx -d qabase.ru -d www.qabase.ru --non-interactive --agree-tos --email admin@qabase.ru

# Проверьте сертификаты
sudo certbot certificates
```

### Шаг 13: Настройка автообновления SSL
```bash
# Включите автоматическое обновление сертификатов
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# Проверьте статус
sudo systemctl status certbot.timer
```

---

## ✅ ПРОВЕРКА РАБОТЫ

### Шаг 14: Тестирование HTTP
```bash
# Проверьте HTTP редирект
curl -I http://qabase.ru

# Проверьте HTTPS
curl -I https://qabase.ru

# Проверьте статус API
curl -f https://qabase.ru/status
```

### Шаг 15: Тестирование WebSocket
```bash
# Установите wscat для тестирования WebSocket
npm install -g wscat

# Тест WebSocket соединения
wscat -c wss://qabase.ru/websocket?username=test

# Отправьте тестовое сообщение
{"type": "chat", "content": "Hello from server!"}
```

### Шаг 16: Проверка в браузере
```bash
# Откройте в браузере:
# https://qabase.ru - основной сайт
# https://qabase.ru/status - статус сервера
```

---

## 🚨 УСТРАНЕНИЕ НЕПОЛАДОК

### Если Go не собирается:
```bash
# Проверьте версию Go
go version

# Обновите Go до версии 1.21+
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
```

### Если nginx не запускается:
```bash
# Проверьте конфигурацию
sudo nginx -t

# Посмотрите логи
sudo tail -f /var/log/nginx/error.log

# Проверьте, не заняты ли порты
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
```

### Если WebSocket сервер не запускается:
```bash
# Проверьте логи
sudo journalctl -u websocket-server -f

# Проверьте права доступа
ls -la /var/www/qabase/server/websocket-server

# Запустите вручную для диагностики
cd /var/www/qabase/server
sudo -u www-data ./websocket-server
```

### Если SSL не работает:
```bash
# Проверьте сертификаты
sudo certbot certificates

# Обновите сертификаты вручную
sudo certbot renew

# Проверьте nginx конфигурацию
sudo nginx -t
```

---

## 📊 ФИНАЛЬНАЯ ПРОВЕРКА

### Шаг 17: Полная диагностика
```bash
# Используйте скрипт управления для проверки
cd /var/www/qabase
./deploy/manage.sh status
./deploy/manage.sh test
```

### Шаг 18: Мониторинг
```bash
# Проверьте все сервисы
sudo systemctl status websocket-server
sudo systemctl status nginx
sudo systemctl status certbot.timer

# Проверьте логи
sudo journalctl -u websocket-server -n 50
sudo tail -f /var/log/nginx/qabase.ru.access.log
```

---

## 🎉 ГОТОВО!

После выполнения всех шагов ваш WebSocket сервер будет доступен по адресам:

- **🌐 Сайт**: https://qabase.ru
- **🔌 WebSocket**: wss://qabase.ru/websocket
- **📊 Статус**: https://qabase.ru/status

### 📋 Полезные команды для управления:
```bash
# Управление сервером
./deploy/manage.sh start      # Запустить
./deploy/manage.sh stop       # Остановить
./deploy/manage.sh restart    # Перезапустить
./deploy/manage.sh status     # Статус
./deploy/manage.sh logs       # Логи
./deploy/manage.sh backup     # Резервная копия
```

---

## 📞 Поддержка

При возникновении проблем:
1. Проверьте логи: `sudo journalctl -u websocket-server -f`
2. Проверьте nginx: `sudo nginx -t`
3. Проверьте статус: `./deploy/manage.sh status`
4. Создайте резервную копию: `./deploy/manage.sh backup`
