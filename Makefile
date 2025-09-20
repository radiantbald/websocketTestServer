# WebSocket Test Server Makefile

.PHONY: help install run build clean test

# Default target
help:
	@echo "WebSocket Test Server - Available commands:"
	@echo ""
	@echo "  make install    - Install Go dependencies"
	@echo "  make run        - Run the server"
	@echo "  make build      - Build the server binary"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make test       - Run tests"
	@echo "  make help       - Show this help message"

# Install dependencies
install:
	@echo "📦 Installing dependencies..."
	cd server && go mod tidy

# Run the server
run:
	@echo "🚀 Starting WebSocket Test Server..."
	@echo "📱 Open http://localhost:9092 in your browser"
	@echo "🔌 WebSocket endpoint: ws://localhost:9092/ws"
	cd server && go run main.go

# Build the server binary
build:
	@echo "🔨 Building server binary..."
	cd server && go build -o websocket-server main.go
	@echo "✅ Binary built: server/websocket-server"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	cd server && rm -f websocket-server
	@echo "✅ Cleaned"

# Run tests
test:
	@echo "🧪 Running tests..."
	cd server && go test ./...

# Development mode with auto-reload (requires air)
dev:
	@echo "🔄 Starting development mode with auto-reload..."
	@echo "Install air with: go install github.com/cosmtrek/air@latest"
	cd server && air
