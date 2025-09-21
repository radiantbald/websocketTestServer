# 🌐 Настройка домена qabase.ru

## 📋 Пошаговая инструкция

### 1️⃣ **Проверка сервиса**
```bash
cd /var/www/qabase
./deploy/check-nginx.sh
```

### 2️⃣ **Настройка DNS**
- Зайдите в панель управления доменом
- Создайте A-запись: `qabase.ru` → `IP_АДРЕС_СЕРВЕРА`
- Создайте A-запись: `www.qabase.ru` → `IP_АДРЕС_СЕРВЕРА`
- Подождите 5-15 минут для распространения DNS

### 3️⃣ **Проверка DNS**
```bash
# Проверить DNS запись
dig qabase.ru
nslookup qabase.ru

# Должно показать IP адрес вашего сервера
```

### 4️⃣ **Настройка SSL сертификатов**
```bash
cd /var/www/qabase
./deploy/setup-ssl.sh
```

### 5️⃣ **Проверка доступности**
```bash
# Проверить HTTP (должен редиректить на HTTPS)
curl -I http://qabase.ru

# Проверить HTTPS
curl -I https://qabase.ru

# Проверить WebSocket
curl -I https://qabase.ru/ws
```

## 🔧 **Команды для диагностики**

### **Проверка Nginx**
```bash
# Статус Nginx
sudo systemctl status nginx

# Проверка конфигурации
sudo nginx -t

# Перезагрузка Nginx
sudo systemctl reload nginx
```

### **Проверка сервиса**
```bash
# Статус WebSocket сервера
sudo systemctl status websocket-server

# Логи сервиса
sudo journalctl -u websocket-server -f
```

### **Проверка портов**
```bash
# Проверить, какие порты слушает Nginx
sudo netstat -tlnp | grep nginx

# Проверить, слушает ли Go сервер на 9092
sudo netstat -tlnp | grep 9092
```

## 🚨 **Типичные проблемы**

### **Проблема: Сайт недоступен**
```bash
# Проверить DNS
dig qabase.ru

# Проверить Nginx
sudo systemctl status nginx

# Проверить конфигурацию
sudo nginx -t
```

### **Проблема: SSL ошибка**
```bash
# Проверить сертификат
sudo certbot certificates

# Обновить сертификат
sudo certbot renew

# Перезагрузить Nginx
sudo systemctl reload nginx
```

### **Проблема: WebSocket не работает**
```bash
# Проверить, что Go сервер запущен
sudo systemctl status websocket-server

# Проверить логи
sudo journalctl -u websocket-server -n 20

# Проверить порт 9092
sudo netstat -tlnp | grep 9092
```

## 📱 **Тестирование**

### **В браузере**
- Откройте: `https://qabase.ru`
- Должна загрузиться тестовая страница WebSocket клиента

### **WebSocket тест**
- Нажмите "Connect" в интерфейсе
- Отправьте сообщение
- Должно появиться в логах сервера

### **API тест**
```bash
# Проверить статус API
curl https://qabase.ru/status

# Должен вернуть JSON с информацией о сервере
```

## 🎯 **Ожидаемый результат**

После настройки:
- ✅ `https://qabase.ru` - доступен
- ✅ `https://www.qabase.ru` - доступен  
- ✅ `https://qabase.ru/ws` - WebSocket endpoint
- ✅ `https://qabase.ru/status` - API статус
- ✅ SSL сертификат действителен
- ✅ Автоматическое обновление SSL

## 🔄 **Обновление**

Для обновления проекта:
```bash
cd /var/www/qabase
./deploy/update.sh
```

Для проверки после обновления:
```bash
./deploy/check-nginx.sh
```
