# 🚀 Быстрый деплой на qabase.ru

## Шаги деплоя (5 минут)

### 1. Подготовка сервера
```bash
# На сервере Timeweb
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx certbot python3-certbot-nginx golang-go
```

### 2. Загрузка проекта
```bash
# Загрузите проект на сервер в /var/www/qabase
# Установите права
sudo chown -R www-data:www-data /var/www/qabase
sudo chmod +x /var/www/qabase/deploy/*.sh
```

### 3. Автоматический деплой
```bash
cd /var/www/qabase
sudo ./deploy/deploy.sh
```

### 4. SSL сертификаты
```bash
sudo ./deploy/ssl-setup.sh
```

### 5. Проверка
```bash
# Проверяем статус
./deploy/manage.sh status

# Тестируем соединение
./deploy/manage.sh test
```

## ✅ Готово!

Ваш WebSocket сервер доступен по адресам:
- **Сайт**: https://qabase.ru
- **WebSocket**: wss://qabase.ru/ws
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
