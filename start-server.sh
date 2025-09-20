#!/bin/bash

# WebSocket Test Server Startup Script

echo "🚀 Starting WebSocket Test Server..."

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go 1.21 or newer."
    exit 1
fi

# Navigate to server directory
cd server

# Install dependencies
echo "📦 Installing dependencies..."
go mod tidy

# Start the server
echo "🌟 Starting server on port 9092..."
echo "📱 Open http://localhost:9092 in your browser"
echo "🔌 WebSocket endpoint: ws://localhost:9092/ws"
echo ""
echo "Press Ctrl+C to stop the server"

go run main.go
