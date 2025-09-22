# WebSocket Test Server - Упрощенный Makefile

.PHONY: help build run test clean deploy status logs restart

# Переменные
BINARY_NAME=websocket-server
BUILD_DIR=server
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
	@curl -f -s http://localhost:9092/websocket > /dev/null && echo "$(GREEN)✅ /websocket доступен$(NC)" || echo "$(RED)❌ /websocket недоступен$(NC)"

clean: ## Очистить собранные файлы
	@echo "$(GREEN)Очищаем собранные файлы...$(NC)"
	rm -f $(BUILD_DIR)/$(BINARY_NAME)
	@echo "$(GREEN)✅ Очистка завершена$(NC)"

deploy: ## Полное развертывание на сервере
	@echo "$(GREEN)Начинаем полное развертывание на qabase.ru...$(NC)"
	@echo "$(YELLOW)Убедитесь, что вы находитесь на сервере и имеете права sudo$(NC)"
	./deploy.sh --full-deploy

update: ## Обновить код и перезапустить сервис
	@echo "$(GREEN)Обновляем код и перезапускаем сервис...$(NC)"
	./deploy.sh --update-only

nginx: ## Настроить только nginx
	@echo "$(GREEN)Настраиваем nginx...$(NC)"
	./deploy.sh --nginx-only

ssl: ## Настроить только SSL
	@echo "$(GREEN)Настраиваем SSL сертификаты...$(NC)"
	./deploy.sh --ssl-only

service: ## Настроить только systemd сервис
	@echo "$(GREEN)Настраиваем systemd сервис...$(NC)"
	./deploy.sh --service-only

status: ## Показать статус всех компонентов
	@echo "$(GREEN)Проверяем статус компонентов...$(NC)"
	./deploy.sh --status

logs: ## Показать логи сервиса
	@echo "$(GREEN)Показываем логи WebSocket сервера...$(NC)"
	./deploy.sh --logs

restart: ## Перезапустить сервис
	@echo "$(GREEN)Перезапускаем WebSocket сервер...$(NC)"
	./deploy.sh --restart

# Локальные команды для разработки
dev: build ## Запустить в режиме разработки
	@echo "$(GREEN)Запускаем в режиме разработки...$(NC)"
	cd $(BUILD_DIR) && ./$(BINARY_NAME)

# Команды для продакшена
prod-deploy: ## Полное развертывание на продакшене
	@echo "$(GREEN)Полное развертывание на продакшене...$(NC)"
	./deploy.sh --full-deploy

prod-update: ## Обновление на продакшене
	@echo "$(GREEN)Обновление на продакшене...$(NC)"
	./deploy.sh --update-only

prod-status: ## Статус продакшена
	@echo "$(GREEN)Статус продакшена...$(NC)"
	./deploy.sh --status

prod-logs: ## Логи продакшена
	@echo "$(GREEN)Логи продакшена...$(NC)"
	./deploy.sh --logs