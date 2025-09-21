# Makefile для WebSocket Test Server
# Проект: qabase.ru

.PHONY: help build run test clean deploy ssl-setup manage

# Переменные
BINARY_NAME=websocket-server
BUILD_DIR=server
DEPLOY_DIR=deploy
PROJECT_DIR=/var/www/qabase

# Цвета для вывода
GREEN=\033[0;32m
YELLOW=\033[1;33m
RED=\033[0;31m
NC=\033[0m # No Color

help: ## Показать справку
	@echo "$(GREEN)WebSocket Test Server для qabase.ru$(NC)"
	@echo ""
	@echo "$(YELLOW)Доступные команды:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Собрать Go приложение
	@echo "$(GREEN)Собираем WebSocket сервер...$(NC)"
	cd $(BUILD_DIR) && go mod tidy
	cd $(BUILD_DIR) && go build -o $(BINARY_NAME) main.go
	@echo "$(GREEN)✅ Сборка завершена$(NC)"

run: build ## Запустить сервер локально
	@echo "$(GREEN)Запускаем WebSocket сервер на localhost:9092...$(NC)"
	cd $(BUILD_DIR) && ./$(BINARY_NAME)

test: ## Протестировать сервер
	@echo "$(GREEN)Тестируем WebSocket сервер...$(NC)"
	@echo "$(YELLOW)Проверяем HTTP endpoints...$(NC)"
	@curl -f -s http://localhost:9092/status > /dev/null && echo "$(GREEN)✅ /status работает$(NC)" || echo "$(RED)❌ /status не работает$(NC)"
	@echo "$(YELLOW)Проверяем WebSocket endpoint...$(NC)"
	@curl -f -s http://localhost:9092/ws > /dev/null && echo "$(GREEN)✅ /ws доступен$(NC)" || echo "$(RED)❌ /ws недоступен$(NC)"

clean: ## Очистить собранные файлы
	@echo "$(GREEN)Очищаем собранные файлы...$(NC)"
	rm -f $(BUILD_DIR)/$(BINARY_NAME)
	@echo "$(GREEN)✅ Очистка завершена$(NC)"

deploy: ## Деплой на сервер qabase.ru
	@echo "$(GREEN)Начинаем деплой на qabase.ru...$(NC)"
	@echo "$(YELLOW)Убедитесь, что вы находитесь на сервере и имеете права sudo$(NC)"
	./$(DEPLOY_DIR)/deploy.sh

ssl-setup: ## Настроить SSL сертификаты
	@echo "$(GREEN)Настраиваем SSL сертификаты...$(NC)"
	./$(DEPLOY_DIR)/ssl-setup.sh

manage: ## Управление сервером (используйте: make manage CMD=start|stop|restart|status|logs)
	@if [ -z "$(CMD)" ]; then \
		echo "$(RED)Укажите команду: make manage CMD=start|stop|restart|status|logs|update|test|backup$(NC)"; \
		exit 1; \
	fi
	./$(DEPLOY_DIR)/manage.sh $(CMD)

start: ## Запустить сервер на продакшене
	@make manage CMD=start

stop: ## Остановить сервер на продакшене
	@make manage CMD=stop

restart: ## Перезапустить сервер на продакшене
	@make manage CMD=restart

status: ## Показать статус сервера
	@make manage CMD=status

logs: ## Показать логи сервера
	@make manage CMD=logs

update: ## Обновить код и перезапустить сервер
	@make manage CMD=update

git-update: ## Обновить проект из GitHub (только для сервера)
	@echo "$(GREEN)Обновляем проект из GitHub...$(NC)"
	./deploy/update.sh

git-update-force: ## Принудительное обновление из GitHub
	@echo "$(GREEN)Принудительное обновление из GitHub...$(NC)"
	./deploy/update.sh --force

update-go: ## Обновить Go на сервере
	@echo "$(GREEN)Обновляем Go на сервере...$(NC)"
	./deploy/update-go.sh

force-update-go: ## Принудительно обновить Go (удалить все версии)
	@echo "$(GREEN)Принудительно обновляем Go...$(NC)"
	./deploy/force-update-go.sh

setup-service: ## Настроить systemd сервис
	@echo "$(GREEN)Настраиваем systemd сервис...$(NC)"
	./deploy/setup-service.sh

diagnose-service: ## Диагностика проблем с сервисом
	@echo "$(GREEN)Диагностируем проблемы с сервисом...$(NC)"
	./deploy/diagnose-service.sh

fix-service: ## Исправить проблемы с сервисом
	@echo "$(GREEN)Исправляем проблемы с сервисом...$(NC)"
	./deploy/fix-service.sh

check-nginx: ## Проверить настройку Nginx для qabase.ru
	@echo "$(GREEN)Проверяем настройку Nginx...$(NC)"
	./deploy/check-nginx.sh

setup-ssl: ## Настроить SSL сертификаты для qabase.ru
	@echo "$(GREEN)Настраиваем SSL сертификаты...$(NC)"
	./deploy/setup-ssl.sh

fix-nginx: ## Исправить проблемы с Nginx конфигурацией
	@echo "$(GREEN)Исправляем проблемы с Nginx...$(NC)"
	./deploy/fix-nginx.sh

diagnose-nginx: ## Диагностика проблем с запуском Nginx
	@echo "$(GREEN)Диагностируем проблемы с Nginx...$(NC)"
	./deploy/diagnose-nginx.sh

force-fix-nginx: ## Принудительно исправить проблемы с Nginx
	@echo "$(GREEN)Принудительно исправляем проблемы с Nginx...$(NC)"
	./deploy/force-fix-nginx.sh

backup: ## Создать резервную копию
	@make manage CMD=backup

# Команды для разработки
dev: ## Запустить в режиме разработки с автоперезагрузкой
	@echo "$(GREEN)Запускаем в режиме разработки...$(NC)"
	@echo "$(YELLOW)Установите air для автоперезагрузки: go install github.com/cosmtrek/air@latest$(NC)"
	cd $(BUILD_DIR) && air

install-deps: ## Установить зависимости для разработки
	@echo "$(GREEN)Устанавливаем зависимости...$(NC)"
	go install github.com/cosmtrek/air@latest
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

lint: ## Проверить код линтером
	@echo "$(GREEN)Проверяем код линтером...$(NC)"
	cd $(BUILD_DIR) && golangci-lint run

# Информация о проекте
info: ## Показать информацию о проекте
	@echo "$(GREEN)WebSocket Test Server для qabase.ru$(NC)"
	@echo ""
	@echo "$(YELLOW)Структура проекта:$(NC)"
	@echo "  server/     - Go WebSocket сервер"
	@echo "  client/     - HTML клиенты для тестирования"
	@echo "  deploy/     - Скрипты для деплоя"
	@echo "  docs/       - Документация"
	@echo ""
	@echo "$(YELLOW)Основные endpoints:$(NC)"
	@echo "  /           - Тестовый клиент"
	@echo "  /ws         - WebSocket endpoint"
	@echo "  /status     - Статус сервера"
	@echo "  /simple     - Простой тестовый клиент"
	@echo ""
	@echo "$(YELLOW)Продакшен URLs:$(NC)"
	@echo "  https://qabase.ru        - Основной сайт"
	@echo "  wss://qabase.ru/ws       - WebSocket endpoint"
	@echo "  https://qabase.ru/status - Статус сервера"