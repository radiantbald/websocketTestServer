# WebSocket Test Server

Современный WebSocket сервер для тестирования с поддержкой чата, уникальных имен пользователей и real-time коммуникации.

## 🚀 Быстрый старт

### Локальная разработка

```bash
# Клонируйте репозиторий
git clone https://github.com/radiantbald/websocketTestServer.git
cd websocketTestServer

# Запустите сервер
make run
```

Откройте `http://localhost:9092` в браузере для тестирования.

### Развертывание на сервере

```bash
# Подключитесь к серверу
ssh root@your-server-ip

# Клонируйте репозиторий
git clone https://github.com/radiantbald/websocketTestServer.git
cd websocketTestServer

# Полное развертывание
make deploy
```

## 📁 Структура проекта

```
websocket-test-server/
├── server/                    # Go WebSocket сервер
│   ├── main.go               # Основной код сервера
│   ├── go.mod                # Go зависимости
│   └── websocket-server      # Скомпилированный бинарник
├── client/                   # HTML/JavaScript клиент
│   └── websocket-test.html   # Веб-клиент для тестирования
├── deploy/                   # Скрипты развертывания
│   ├── deploy.sh             # Единый скрипт развертывания
│   ├── nginx-qabase.conf     # Конфигурация nginx
│   └── websocket-server.service # Systemd сервис
├── Makefile                  # Команды для управления
└── README.md                 # Документация
```

## ✨ Возможности

- **Real-time чат** с поддержкой множественных клиентов
- **Уникальные имена пользователей** с проверкой дублирования
- **Автоматические предложения** альтернативных имен
- **Современный веб-интерфейс** с адаптивным дизайном
- **WebSocket API** с поддержкой различных типов сообщений
- **REST API** для мониторинга статуса
- **Автоматическое развертывание** с nginx и SSL

## 🛠️ Команды

### Локальная разработка

```bash
make help          # Показать справку
make build         # Собрать приложение
make run           # Запустить сервер локально
make test          # Протестировать сервер
make clean         # Очистить собранные файлы
make dev           # Запустить в режиме разработки
```

### Развертывание на сервере

```bash
make deploy        # Полное развертывание
make update        # Обновить код и перезапустить
make nginx         # Настроить только nginx
make ssl           # Настроить только SSL
make service       # Настроить только systemd сервис
make status        # Показать статус компонентов
make logs          # Показать логи сервиса
make restart       # Перезапустить сервис
```

### Прямые команды скрипта

```bash
./deploy.sh --full-deploy    # Полное развертывание
./deploy.sh --update-only    # Только обновление кода
./deploy.sh --nginx-only     # Только nginx
./deploy.sh --ssl-only       # Только SSL
./deploy.sh --status         # Статус компонентов
./deploy.sh --logs           # Логи сервиса
./deploy.sh --restart        # Перезапуск сервиса
./deploy.sh --help           # Справка
```

## 🌐 API

### WebSocket Endpoint

- **URL**: `ws://localhost:9092/websocket` (локально)
- **URL**: `wss://qabase.ru/websocket` (продакшен)
- **Параметры**: `?username=YourName`

### Типы сообщений

#### Чат сообщение
```json
{
  "type": "chat",
  "content": "Ваше сообщение"
}
```

#### Ping сообщение
```json
{
  "type": "ping"
}
```

#### Echo сообщение
```json
{
  "type": "echo",
  "content": "Сообщение для эха"
}
```

### REST Endpoints

- **GET /status** - Статус сервера и статистика
- **GET /** - HTML клиент для тестирования

## 🔧 Конфигурация

### Переменные окружения

Сервер использует следующие настройки по умолчанию:

- **Порт**: 9092
- **Максимум клиентов**: 100
- **Максимальная длина имени**: 50 символов
- **Максимальная длина сообщения**: 1024 символа

### Nginx конфигурация

Автоматически настраивается для:
- Проксирования WebSocket соединений
- Обслуживания статических файлов
- SSL терминации

### Systemd сервис

Автоматически настраивается для:
- Автозапуска при загрузке системы
- Управления через systemctl
- Логирования в journald

## 🧪 Тестирование

### Базовое тестирование

1. **Подключение**: Откройте `http://localhost:9092` и нажмите "Подключиться"
2. **Чат**: Отправьте сообщение и убедитесь, что оно отображается
3. **Множественные клиенты**: Откройте несколько вкладок с разными именами

### Тестирование дублирования имен

1. Подключитесь с именем "Тест"
2. Попробуйте подключиться с тем же именем в другой вкладке
3. Должно появиться сообщение об ошибке с предложениями альтернативных имен

### Тестирование на продакшене

```bash
# Проверка статуса
curl -f https://qabase.ru/status

# Проверка WebSocket соединения
wscat -c wss://qabase.ru/websocket
```

## 🔒 Безопасность

- **CORS защита** для разрешенных доменов
- **Валидация входных данных** для имен и сообщений
- **Ограничение количества соединений**
- **SSL/TLS шифрование** на продакшене
- **Автоматическое обновление SSL сертификатов**

## 📝 Логирование

Логи доступны через:

```bash
# Логи systemd сервиса
journalctl -u websocket-server -f

# Логи nginx
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

## 🚀 Развертывание

### Требования

- Ubuntu/Debian сервер
- Права root или sudo
- Домен, указывающий на сервер

### Автоматическое развертывание

```bash
# Подключитесь к серверу
ssh root@your-server-ip

# Клонируйте и разверните
git clone https://github.com/radiantbald/websocketTestServer.git
cd websocketTestServer
make deploy
```

### Ручное развертывание

```bash
# 1. Установите зависимости
apt update && apt install -y nginx certbot python3-certbot-nginx golang-go

# 2. Клонируйте проект
git clone https://github.com/radiantbald/websocketTestServer.git /var/www/qabase
cd /var/www/qabase

# 3. Соберите приложение
cd server && go build -o websocket-server main.go

# 4. Настройте сервисы
./deploy.sh --full-deploy
```

## 🤝 Вклад в проект

1. Форкните репозиторий
2. Создайте ветку для новой функции
3. Внесите изменения
4. Протестируйте тщательно
5. Отправьте pull request

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. См. файл LICENSE для подробностей.

## 🆘 Поддержка

Если у вас возникли проблемы:

1. Проверьте логи: `make logs`
2. Проверьте статус: `make status`
3. Перезапустите сервис: `make restart`
4. Создайте issue в GitHub репозитории