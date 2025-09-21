# Обновление маршрутизации WebSocket тестов

## Что было изменено

1. **Добавлен новый маршрут `/websocket`** для доступа к странице с тестами WebSocket
2. **Создана заглушка для корневого пути** - теперь `/` отдает красивую страницу-заглушку
3. **WebSocket тесты доступны только по `/websocket`** - корневой путь зарезервирован под другой функционал

### Изменения в nginx конфигурации

В файлах `deploy/nginx-qabase.conf` и `deploy/nginx-qabase-clean.conf` добавлены новые location блоки:

```nginx
# WebSocket тестовая страница
location /websocket {
    alias /var/www/qabase/client/test-client.html;
    try_files $uri =404;
}

# Главная страница (заглушка)
location = / {
    root /var/www/qabase/client;
    index index.html;
    try_files $uri /index.html;
}

# Статические файлы клиента
location / {
    root /var/www/qabase/client;
    try_files $uri $uri/ =404;
    
    # Кэширование статических файлов
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### Изменения в HTML файлах

1. **Обновлены WebSocket URL** в следующих файлах:
   - `test-client.html`
   - `client/test-client.html` 
   - `client/websocket-test.html`
   
   Изменено с `ws://localhost:9090/websocket` на `wss://qabase.ru/websocket` для продакшена.

2. **Создан новый файл** `client/index.html` - красивая заглушка для главной страницы с:
   - Современным дизайном в стиле сайта
   - Информацией о предстоящих функциях
   - Ссылкой на WebSocket тесты
   - Адаптивной версткой

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
# Скопировать обновленные файлы (включая новую заглушку)
sudo cp -r client/* /var/www/qabase/client/
sudo cp test-client.html /var/www/qabase/client/

# Установить права доступа
sudo chown -R www-data:www-data /var/www/qabase/client
sudo chmod -R 755 /var/www/qabase/client
```

### 3. Проверить работу

После применения изменений страницы будут доступны по адресам:
- **https://qabase.ru** - главная страница с заглушкой (новая)
- **https://qabase.ru/websocket** - страница с тестами WebSocket

## Результат

Теперь пользователи могут:
1. Заходить на **qabase.ru** - красивая главная страница с информацией о платформе
2. Заходить на **qabase.ru/websocket** - страница с тестами WebSocket
3. WebSocket соединение работает через **wss://qabase.ru/websocket**
4. Статус сервера доступен по **https://qabase.ru/status**

**Важно:** Корневой путь `/` теперь зарезервирован под основной функционал платформы, а WebSocket тесты доступны только по специальному пути `/websocket`.

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
