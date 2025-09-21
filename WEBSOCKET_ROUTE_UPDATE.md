# Обновление маршрутизации WebSocket тестов

## Что было изменено

Добавлен новый маршрут `/websocket` для доступа к странице с тестами WebSocket.

### Изменения в nginx конфигурации

В файлах `deploy/nginx-qabase.conf` и `deploy/nginx-qabase-clean.conf` добавлен новый location блок:

```nginx
# WebSocket тестовая страница
location /websocket {
    alias /var/www/qabase/client/test-client.html;
    try_files $uri =404;
}
```

### Изменения в HTML файлах

Обновлены WebSocket URL в следующих файлах:
- `test-client.html`
- `client/test-client.html` 
- `client/websocket-test.html`

Изменено с `ws://localhost:9090/ws` на `wss://qabase.ru/ws` для продакшена.

## Как применить изменения

### 1. Обновить конфигурацию nginx на сервере

```bash
# Скопировать новую конфигурацию
sudo cp deploy/nginx-qabase.conf /etc/nginx/sites-available/qabase.ru

# Проверить конфигурацию
sudo nginx -t

# Перезагрузить nginx
sudo systemctl reload nginx
```

### 2. Обновить файлы клиента

```bash
# Скопировать обновленные файлы
sudo cp -r client/* /var/www/qabase/client/
sudo cp test-client.html /var/www/qabase/client/

# Установить права доступа
sudo chown -R www-data:www-data /var/www/qabase/client
sudo chmod -R 755 /var/www/qabase/client
```

### 3. Проверить работу

После применения изменений страница с тестами WebSocket будет доступна по адресу:
- **https://qabase.ru/websocket** - новая страница с тестами
- **https://qabase.ru** - основная страница (как было)

## Результат

Теперь пользователи могут:
1. Заходить на **qabase.ru** - основная страница
2. Заходить на **qabase.ru/websocket** - страница с тестами WebSocket
3. WebSocket соединение работает через **wss://qabase.ru/ws**
4. Статус сервера доступен по **https://qabase.ru/status**

## Автоматический деплой

Для полного обновления можно использовать скрипт деплоя:

```bash
./deploy/deploy.sh
```

Этот скрипт автоматически:
- Скопирует все файлы
- Обновит конфигурацию nginx
- Перезапустит сервисы
- Проверит работоспособность
