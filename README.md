# WebSocket Test Server

A comprehensive WebSocket testing solution with a Go server and modern HTML/JavaScript client for manual testing practice.

## Project Structure

```
websocket-test-server/
├── server/           # Go WebSocket server
│   ├── main.go       # Server implementation
│   ├── go.mod        # Go dependencies
│   └── README.md     # Server documentation
├── client/           # HTML/JavaScript client
│   ├── test-client.html      # Main client interface
│   ├── websocket-test.html   # Simple test client
│   └── README.md     # Client documentation
├── docs/             # Documentation
│   ├── PROXYMAN_SETUP.md
│   ├── WEBSOCKET_PROXYMAN_SETUP.md
│   └── README.md
└── README.md         # This file
```

## Features

- **Real-time messaging**: Chat functionality with broadcast messaging
- **Connection management**: Automatic client registration/unregistration
- **Message types**: Support for chat, ping/pong, echo, and system messages
- **Multiple clients**: Support for multiple simultaneous connections (max 100)
- **Modern client interface**: Responsive HTML client with mobile support
- **Proxyman integration**: Built-in support for traffic analysis
- **Detailed logging**: Server-side logging for debugging
- **REST API**: Status endpoint for server monitoring
- **Security features**: CORS protection, input validation, rate limiting
- **Automated security checks**: GitHub Actions for vulnerability scanning

## Quick Start

### Prerequisites

- Go 1.21 or newer
- Web browser for testing

### Installation and Running

1. **Clone or download the project files**

2. **Install server dependencies**:
   ```bash
   cd server
   go mod tidy
   ```

3. **Run the server**:
   ```bash
   go run main.go
   ```

4. **Open the test client**:
   - Navigate to `http://localhost:9092` in your browser
   - Or open `client/test-client.html` directly

## Components

### Server (`/server`)

Go-based WebSocket server with:
- WebSocket endpoint at `ws://localhost:9092/ws`
- REST API for status monitoring
- Support for multiple message types
- Comprehensive logging

[Server Documentation](server/README.md)

### Client (`/client`)

Modern HTML/JavaScript client with:
- Responsive design with mobile support
- Real-time chat interface
- Test scenarios and debugging tools
- Proxyman integration for traffic analysis

[Client Documentation](client/README.md)

### Documentation (`/docs`)

Additional documentation for:
- Proxyman setup and configuration
- WebSocket traffic analysis
- Advanced testing scenarios

[Documentation](docs/README.md)

## Testing Scenarios

### Basic Connection Testing

1. **Single Connection**:
   - Click "Connect" to establish a WebSocket connection
   - Verify the status changes to "Connected"
   - Check server logs for connection confirmation

2. **Multiple Connections**:
   - Open multiple browser tabs/windows
   - Connect from each tab with different usernames
   - Verify all connections are registered

### Message Testing

1. **Chat Messages**:
   - Send text messages between connected clients
   - Verify message broadcasting to all clients
   - Test message formatting and display

2. **Ping/Pong**:
   - Use the "Ping" button to test connection health
   - Verify pong responses in the message log

3. **Echo Messages**:
   - Send echo messages to test server response
   - Verify echo functionality works correctly

### Advanced Testing

1. **Connection Stability**:
   - Test connection recovery after network issues
   - Verify automatic reconnection behavior

2. **Error Handling**:
   - Test invalid JSON messages
   - Verify error message handling

3. **Performance Testing**:
   - Use "Rapid Messages" to test high-frequency messaging
   - Monitor server performance under load

## Proxyman Integration

For advanced traffic analysis:

1. **Setup Proxyman** on port 9090
2. **Configure client** to connect through Proxyman
3. **Monitor WebSocket traffic** in real-time

[Proxyman Setup Guide](docs/PROXYMAN_SETUP.md)

## API Reference

### WebSocket Endpoint

- **URL**: `ws://localhost:9092/ws`
- **Parameters**: `?username=YourName`

### Message Types

#### Chat Message
```json
{
  "type": "chat",
  "content": "Your message here"
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
  "content": "Message to echo"
}
```

### REST Endpoints

- **GET /status** - Server status and statistics
- **GET /** - HTML test client (if configured)

## Development

### Server Development

```bash
cd server
go run main.go
```

### Client Development

Open `client/test-client.html` in your browser for development and testing.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Security

This project includes several security features:

- **CORS Protection**: Restricted to localhost and development domains
- **Input Validation**: Username and message content validation
- **Rate Limiting**: Maximum 100 concurrent connections
- **Error Handling**: Graceful error responses and logging

⚠️ **Important**: This is a test server for development purposes. For production use, implement additional security measures as outlined in [SECURITY.md](SECURITY.md).

### Security Checks

The project includes automated security checks via GitHub Actions:
- Vulnerability scanning with `govulncheck`
- Static code analysis with `staticcheck`
- Secret detection with TruffleHog
- Dependency vulnerability checks

## License

This project is open source and available under the MIT License.