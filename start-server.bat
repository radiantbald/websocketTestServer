@echo off
REM WebSocket Test Server Startup Script for Windows

echo 🚀 Starting WebSocket Test Server...

REM Check if Go is installed
go version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Go is not installed. Please install Go 1.21 or newer.
    pause
    exit /b 1
)

REM Navigate to server directory
cd server

REM Install dependencies
echo 📦 Installing dependencies...
go mod tidy

REM Start the server
echo 🌟 Starting server on port 9092...
echo 📱 Open http://localhost:9092 in your browser
echo 🔌 WebSocket endpoint: ws://localhost:9092/websocket
echo.
echo Press Ctrl+C to stop the server

go run main.go
