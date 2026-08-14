package server

import (
	"encoding/json"
	"net/http"
	"sync"
	"time"

	"veil-signal-server/internal/models"

	"github.com/gorilla/websocket" // <-- ЭТОТ ИМПОРТ
)

type WebSocketServer struct {
	*Server
	clients    map[string]*websocket.Conn
	clientsMux sync.RWMutex
	upgrader   websocket.Upgrader
}

func NewWebSocketServer(server *Server) *WebSocketServer {
	return &WebSocketServer{
		Server:  server,
		clients: make(map[string]*websocket.Conn),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true
			},
			ReadBufferSize:  1024,
			WriteBufferSize: 1024,
		},
	}
}

func (ws *WebSocketServer) HandleWS(w http.ResponseWriter, r *http.Request) {
	userID := r.URL.Query().Get("userId")
	if userID == "" {
		http.Error(w, "Missing userId", http.StatusBadRequest)
		return
	}

	if blocked, _ := ws.storage.IsBlocked(userID); blocked {
		http.Error(w, "Blocked", http.StatusForbidden)
		return
	}

	conn, err := ws.upgrader.Upgrade(w, r, nil)
	if err != nil {
		return
	}
	defer conn.Close()

	// Сохраняем клиента
	ws.clientsMux.Lock()
	ws.clients[userID] = conn
	ws.clientsMux.Unlock()

	defer func() {
		ws.clientsMux.Lock()
		delete(ws.clients, userID)
		ws.clientsMux.Unlock()
	}()

	// Отправляем старые сообщения при подключении
	messages, _ := ws.storage.GetMessages(userID)
	for _, msg := range messages {
		data, _ := json.Marshal(msg)
		conn.WriteMessage(websocket.TextMessage, data)
	}
	ws.storage.DeleteMessages(userID)

	// Слушаем сообщения
	for {
		var msg models.Message
		if err := conn.ReadJSON(&msg); err != nil {
			break
		}

		// Сохраняем сообщение
		msg.Timestamp = time.Now()
		ws.storage.SaveMessage(msg)

		// Отправляем получателю, если онлайн
		ws.clientsMux.RLock()
		targetConn, ok := ws.clients[msg.To]
		ws.clientsMux.RUnlock()

		if ok {
			data, _ := json.Marshal(msg)
			targetConn.WriteMessage(websocket.TextMessage, data)
		}
	}
}
