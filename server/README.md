# WebSocket Server

Go-сервер для WebSocket тестирования с поддержкой чата и уникальных имен пользователей.

## 🚀 Быстрый старт

```bash
# Установите зависимости
go mod tidy

# Запустите сервер
go run main.go
```

Сервер будет доступен на `http://localhost:9092`

## ✨ Возможности

- **WebSocket соединения** с поддержкой множественных клиентов
- **Уникальные имена пользователей** с проверкой дублирования
- **Real-time чат** с рассылкой сообщений всем клиентам
- **Различные типы сообщений**: chat, ping, echo, system
- **Валидация данных** для безопасности
- **Логирование** всех операций
- **REST API** для мониторинга

## 🔧 Конфигурация

### Переменные

```go
const (
    MaxMessageSize = 1024  // Максимальный размер сообщения
    MaxUsernameLen = 50    // Максимальная длина имени пользователя
    MaxClients     = 100   // Максимальное количество клиентов
)
```

### Порт

По умолчанию сервер запускается на порту `:9092`. Для изменения порта отредактируйте переменную `port` в функции `main()`.

## 🌐 API

### WebSocket Endpoint

- **URL**: `ws://localhost:9092/websocket`
- **Параметры**: `?username=YourName`

### Типы сообщений

#### Chat Message
```json
{
  "type": "chat",
  "content": "Ваше сообщение"
}
```

#### Ping Message
```json
{
  "type": "ping"
}
```

#### Echo Message
```json
{
  "type": "echo",
  "content": "Сообщение для эха"
}
```

### REST Endpoints

- **GET /status** - Статус сервера
- **GET /** - HTML клиент
- **GET /simple** - Простой клиент

## 🔒 Безопасность

### Валидация имен пользователей

- Проверка на пустые имена
- Ограничение длины (максимум 50 символов)
- Удаление опасных символов (`<>\"'&`)
- Проверка уникальности

### Валидация сообщений

- Проверка на пустые сообщения
- Ограничение длины (максимум 1024 символа)
- Удаление HTML тегов
- Очистка от лишних пробелов

### CORS защита

Разрешенные домены:
- `https://qabase.ru`
- `http://qabase.ru`
- `https://www.qabase.ru`
- `http://www.qabase.ru`
- `http://localhost:9092`
- `http://127.0.0.1:9092`

## 📊 Мониторинг

### Логирование

Сервер логирует:
- Подключения и отключения клиентов
- Отправленные сообщения
- Ошибки валидации
- Отклоненные соединения

### Статистика

Endpoint `/status` возвращает:
```json
{
  "status": "running",
  "timestamp": "2025-09-21T11:00:00Z",
  "endpoints": [
    "/websocket - WebSocket endpoint",
    "/api/websocket - WebSocket API endpoint",
    "/status - Server status",
    "/ - Test client page"
  ]
}
```

## 🧪 Тестирование

### Локальное тестирование

```bash
# Запустите сервер
go run main.go

# В другом терминале протестируйте
curl http://localhost:9092/status
```

### WebSocket тестирование

Используйте встроенный HTML клиент:
1. Откройте `http://localhost:9092`
2. Введите имя пользователя
3. Нажмите "Подключиться"
4. Отправьте сообщение

### Тестирование дублирования имен

1. Подключитесь с именем "Тест"
2. Попробуйте подключиться с тем же именем
3. Должно появиться сообщение об ошибке

## 🔧 Разработка

### Структура кода

```go
// Message - структура сообщения
type Message struct {
    Type      string    `json:"type"`
    Content   string    `json:"content"`
    Username  string    `json:"username,omitempty"`
    Timestamp time.Time `json:"timestamp"`
    ClientID  string    `json:"clientId,omitempty"`
}

// Client - структура клиента
type Client struct {
    ID       string
    Conn     *websocket.Conn
    Send     chan Message
    Username string
}

// Hub - центральный хаб для управления клиентами
type Hub struct {
    clients    map[*Client]bool
    usernames  map[string]bool
    broadcast  chan Message
    register   chan *Client
    unregister chan *Client
}
```

### Добавление новых типов сообщений

1. Добавьте новый тип в switch в `ReadPump()`
2. Обработайте логику в соответствующем case
3. Обновите документацию

### Изменение валидации

Отредактируйте функции:
- `validateUsername()` - для имен пользователей
- `validateMessageContent()` - для содержимого сообщений

## 📦 Сборка

```bash
# Сборка для текущей платформы
go build -o websocket-server main.go

# Сборка для Linux (для продакшена)
GOOS=linux GOARCH=amd64 go build -o websocket-server main.go
```

## 🚀 Развертывание

### Systemd сервис

Создайте файл `/etc/systemd/system/websocket-server.service`:

```ini
[Unit]
Description=WebSocket Test Server
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/qabase/server
ExecStart=/var/www/qabase/server/websocket-server
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### Nginx конфигурация

```nginx
server {
    listen 80;
    server_name qabase.ru www.qabase.ru;
    
    location / {
        proxy_pass http://localhost:9092;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 🐛 Отладка

### Проблемы с подключением

1. Проверьте, что порт 9092 свободен
2. Убедитесь, что файрвол не блокирует порт
3. Проверьте логи сервера

### Проблемы с WebSocket

1. Убедитесь, что nginx правильно проксирует WebSocket
2. Проверьте заголовки Upgrade и Connection
3. Проверьте SSL сертификаты для wss://

### Проблемы с именами пользователей

1. Проверьте логи валидации
2. Убедитесь, что имена не содержат запрещенные символы
3. Проверьте длину имен

## 📝 Changelog

### v1.0.0
- Базовая функциональность WebSocket сервера
- Поддержка чата с множественными клиентами
- Уникальные имена пользователей
- Валидация данных
- REST API для мониторинга