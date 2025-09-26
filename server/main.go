package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/gorilla/websocket"
)

// Message represents a WebSocket message
type Message struct {
	Type      string    `json:"type"`
	Content   string    `json:"content"`
	Username  string    `json:"username,omitempty"`
	Timestamp time.Time `json:"timestamp"`
	ClientID  string    `json:"clientId,omitempty"`
}

// Client represents a WebSocket client connection
type Client struct {
	ID       string
	Conn     *websocket.Conn
	Send     chan Message
	Username string
}

// Hub maintains the set of active clients and broadcasts messages
type Hub struct {
	clients    map[*Client]bool
	usernames  map[string]bool // Отслеживание занятых имен пользователей
	broadcast  chan Message
	register   chan *Client
	unregister chan *Client
}

// Константы для валидации
const (
	MaxMessageSize = 1024 // Максимальный размер сообщения
	MaxUsernameLen = 50   // Максимальная длина имени пользователя
	MaxClients     = 100  // Максимальное количество клиентов
)

// Валидация имени пользователя
func validateUsername(username string) (string, error) {
	if len(username) == 0 {
		return "", fmt.Errorf("username cannot be empty")
	}

	if len(username) > MaxUsernameLen {
		return "", fmt.Errorf("username too long (max %d characters)", MaxUsernameLen)
	}

	// Удаляем потенциально опасные символы
	reg := regexp.MustCompile(`[<>\"'&]`)
	cleanUsername := reg.ReplaceAllString(username, "")

	// Удаляем лишние пробелы
	cleanUsername = strings.TrimSpace(cleanUsername)

	if len(cleanUsername) == 0 {
		return "", fmt.Errorf("username contains only invalid characters")
	}

	return cleanUsername, nil
}

// Валидация содержимого сообщения
func validateMessageContent(content string) (string, error) {
	if len(content) == 0 {
		return "", fmt.Errorf("message content cannot be empty")
	}

	if len(content) > MaxMessageSize {
		return "", fmt.Errorf("message too long (max %d characters)", MaxMessageSize)
	}

	// Удаляем потенциально опасные HTML теги
	reg := regexp.MustCompile(`<[^>]*>`)
	cleanContent := reg.ReplaceAllString(content, "")

	// Удаляем лишние пробелы
	cleanContent = strings.TrimSpace(cleanContent)

	if len(cleanContent) == 0 {
		return "", fmt.Errorf("message contains only HTML tags")
	}

	return cleanContent, nil
}

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		// В продакшене замените на конкретные домены
		origin := r.Header.Get("Origin")
		if origin == "" {
			// Разрешаем подключения без Origin (например, из Postman)
			return true
		}

		// Разрешенные домены для продакшена
		allowedOrigins := []string{
			"https://qabase.ru",
			"http://qabase.ru",
			"https://www.qabase.ru",
			"http://www.qabase.ru",
			// Домены для разработки (можно удалить в продакшене)
			"http://localhost:9092",
			"http://127.0.0.1:9092",
			"http://localhost:3000",
			"http://127.0.0.1:3000",
		}

		for _, allowed := range allowedOrigins {
			if origin == allowed {
				return true
			}
		}

		log.Printf("Rejected connection from origin: %s", origin)
		return false
	},
}

func NewHub() *Hub {
	return &Hub{
		clients:    make(map[*Client]bool),
		usernames:  make(map[string]bool),
		broadcast:  make(chan Message),
		register:   make(chan *Client),
		unregister: make(chan *Client),
	}
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			// Проверяем лимит клиентов
			if len(h.clients) >= MaxClients {
				log.Printf("Rejected client %s: server at capacity (%d/%d)", client.ID, len(h.clients), MaxClients)
				errorMessage := Message{
					Type:      "error",
					Content:   "Server is at capacity. Please try again later.",
					Timestamp: time.Now(),
				}
				client.Send <- errorMessage
				close(client.Send)
				client.Conn.Close()
				continue
			}

			// Проверяем уникальность имени пользователя
			if h.usernames[client.Username] {
				log.Printf("Rejected client %s: username '%s' is already taken", client.ID, client.Username)
				errorMessage := Message{
					Type:      "error",
					Content:   fmt.Sprintf("❌ Пользователь с именем '%s' уже подключен к чату. Пожалуйста, выберите другое имя.", client.Username),
					Timestamp: time.Now(),
				}
				client.Send <- errorMessage
				close(client.Send)
				// Закрываем соединение с кодом 1008 и понятным сообщением
				client.Conn.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(1008, "Пользователь с таким именем уже подключен, придумайте другое имя"))
				client.Conn.Close()
				continue
			}

			// Регистрируем клиента
			h.clients[client] = true
			h.usernames[client.Username] = true
			log.Printf("Client %s connected as '%s'. Total clients: %d", client.ID, client.Username, len(h.clients))

			// Send welcome message to the new client
			welcomeMessage := Message{
				Type:      "system",
				Content:   fmt.Sprintf("Welcome! You are connected as %s", client.Username),
				Timestamp: time.Now(),
			}
			client.Send <- welcomeMessage

			// Notify other clients about new connection
			joinMessage := Message{
				Type:      "system",
				Content:   fmt.Sprintf("%s joined the chat", client.Username),
				Timestamp: time.Now(),
			}
			h.BroadcastToOthers(client, joinMessage)

		case client := <-h.unregister:
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				delete(h.usernames, client.Username) // Освобождаем имя пользователя
				close(client.Send)
				log.Printf("Client %s disconnected as '%s'. Total clients: %d", client.ID, client.Username, len(h.clients))

				// Notify other clients about disconnection
				leaveMessage := Message{
					Type:      "system",
					Content:   fmt.Sprintf("%s left the chat", client.Username),
					Timestamp: time.Now(),
				}
				h.BroadcastToOthers(client, leaveMessage)
			}

		case message := <-h.broadcast:
			for client := range h.clients {
				select {
				case client.Send <- message:
				default:
					close(client.Send)
					delete(h.clients, client)
				}
			}
		}
	}
}

func (h *Hub) BroadcastToOthers(sender *Client, message Message) {
	for client := range h.clients {
		if client != sender {
			select {
			case client.Send <- message:
			default:
				close(client.Send)
				delete(h.clients, client)
			}
		}
	}
}

func (c *Client) ReadPump(hub *Hub) {
	defer func() {
		hub.unregister <- c
		c.Conn.Close()
	}()

	c.Conn.SetReadLimit(512)
	c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.Conn.SetPongHandler(func(string) error {
		c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		var msg Message
		err := c.Conn.ReadJSON(&msg)
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("WebSocket error: %v", err)
			}
			break
		}

		// Валидируем содержимое сообщения (кроме ping/pong)
		if msg.Type != "ping" && msg.Type != "pong" {
			validatedContent, err := validateMessageContent(msg.Content)
			if err != nil {
				log.Printf("Invalid message content from %s: %v", c.Username, err)
				errorMessage := Message{
					Type:      "error",
					Content:   fmt.Sprintf("Invalid message: %v", err),
					Username:  "Server",
					Timestamp: time.Now(),
				}
				c.Send <- errorMessage
				continue
			}
			msg.Content = validatedContent
		}

		// Set client information
		msg.Username = c.Username
		msg.ClientID = c.ID
		msg.Timestamp = time.Now()

		// Handle different message types
		switch msg.Type {
		case "chat":
			log.Printf("Chat message from %s: %s", c.Username, msg.Content)
			hub.broadcast <- msg
		case "ping":
			// Respond to ping with pong
			log.Printf("Ping received from %s", c.Username)
			pongMessage := Message{
				Type:      "pong",
				Content:   "pong",
				Username:  "Server",
				Timestamp: time.Now(),
			}
			c.Send <- pongMessage
			log.Printf("Pong sent to %s", c.Username)
		case "echo":
			// Echo the message back to the sender
			echoMessage := Message{
				Type:      "echo",
				Content:   fmt.Sprintf("Echo: %s", msg.Content),
				Username:  "Server",
				Timestamp: time.Now(),
			}
			c.Send <- echoMessage
		default:
			log.Printf("Unknown message type from %s: %s", c.Username, msg.Type)
			errorMessage := Message{
				Type:      "error",
				Content:   fmt.Sprintf("Unknown message type: %s", msg.Type),
				Username:  "Server",
				Timestamp: time.Now(),
			}
			c.Send <- errorMessage
		}
	}
}

func (c *Client) WritePump() {
	ticker := time.NewTicker(54 * time.Second)
	defer func() {
		ticker.Stop()
		c.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.Send:
			c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			if err := c.Conn.WriteJSON(message); err != nil {
				log.Printf("Write error: %v", err)
				return
			}

		case <-ticker.C:
			c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func HandleWebSocket(hub *Hub, w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		return
	}

	// Get username from query parameter
	username := r.URL.Query().Get("username")
	if username == "" {
		username = fmt.Sprintf("User_%d", time.Now().Unix())
	}

	// Валидируем имя пользователя
	validatedUsername, err := validateUsername(username)
	if err != nil {
		log.Printf("Invalid username: %v", err)
		conn.Close()
		return
	}

	client := &Client{
		ID:       fmt.Sprintf("client_%d", time.Now().UnixNano()),
		Conn:     conn,
		Send:     make(chan Message, 256),
		Username: validatedUsername,
	}

	client.Conn.SetCloseHandler(func(code int, text string) error {
		log.Printf("WebSocket closed: %d %s", code, text)
		return nil
	})

	hub.register <- client

	go client.WritePump()
	go client.ReadPump(hub)
}

func HandleRoot(w http.ResponseWriter, r *http.Request) {
	http.ServeFile(w, r, "../client/test-client.html")
}

func HandleSimple(w http.ResponseWriter, r *http.Request) {
	http.ServeFile(w, r, "../client/websocket-test.html")
}

func HandleStatus(w http.ResponseWriter, r *http.Request) {
	// Добавляем заголовки безопасности
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("X-Frame-Options", "DENY")
	w.Header().Set("X-XSS-Protection", "1; mode=block")
	w.Header().Set("Referrer-Policy", "strict-origin-when-cross-origin")

	status := map[string]interface{}{
		"status":    "running",
		"timestamp": time.Now(),
		"endpoints": []string{
			"/websocket - WebSocket test page (HTTP) or WebSocket endpoint (WS)",
			"/api/websocket - WebSocket API endpoint",
			"/status - Server status",
			"/ - Test client page",
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(status)
}

func main() {
	hub := NewHub()
	go hub.Run()

	http.HandleFunc("/", HandleRoot)
	http.HandleFunc("/simple", HandleSimple)
	http.HandleFunc("/websocket", func(w http.ResponseWriter, r *http.Request) {
		// Если это WebSocket запрос, обрабатываем как WebSocket
		if r.Header.Get("Upgrade") == "websocket" {
			HandleWebSocket(hub, w, r)
		} else {
			// Если это обычный HTTP запрос, отдаем тестовую страницу
			http.ServeFile(w, r, "../client/websocket-test.html")
		}
	})
	http.HandleFunc("/api/websocket", func(w http.ResponseWriter, r *http.Request) {
		HandleWebSocket(hub, w, r)
	})
	http.HandleFunc("/status", HandleStatus)

	port := ":9092"
	log.Printf("WebSocket test server starting on port %s", port)
	log.Printf("Open http://localhost%s in your browser to test", port)
	log.Printf("WebSocket endpoint: ws://localhost%s/websocket", port)

	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatal("Server failed to start:", err)
	}
}
