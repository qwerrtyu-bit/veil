package server

import (
	"encoding/json"
	"net/http"
	"time"
	"veil-signal-server/internal/models"
)

func (s *Server) RegisterHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req models.RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	if blocked, _ := s.storage.IsBlocked(req.UserID); blocked {
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  "blocked",
			"message": "Your key is blocked",
		})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "ok",
	})
}

func (s *Server) SendHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req models.SendRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	if blocked, _ := s.storage.IsBlocked(req.From); blocked {
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status": "blocked",
		})
		return
	}

	msg := models.Message{
		ID:        req.ID,
		From:      req.From,
		To:        req.To,
		ChatID:    req.ChatID,
		Text:      req.Text,
		Timestamp: time.Now(),
		Delivered: false,
	}

	if err := s.storage.SaveMessage(msg); err != nil {
		http.Error(w, "Failed to save message", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "ok",
	})
}

func (s *Server) PollHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID := r.URL.Query().Get("userId")
	if userID == "" {
		http.Error(w, "Missing userId", http.StatusBadRequest)
		return
	}

	if blocked, _ := s.storage.IsBlocked(userID); blocked {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(models.PollResponse{
			Messages: []models.Message{},
			Blocked:  true,
		})
		return
	}

	messages, err := s.storage.GetMessages(userID)
	if err != nil {
		http.Error(w, "Failed to get messages", http.StatusInternalServerError)
		return
	}

	if err := s.storage.DeleteMessages(userID); err != nil {
		http.Error(w, "Failed to delete messages", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(models.PollResponse{
		Messages: messages,
	})
}

func (s *Server) BlockHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var data map[string]string
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	key, ok := data["key"]
	if !ok || key == "" {
		http.Error(w, "Missing key", http.StatusBadRequest)
		return
	}

	if err := s.storage.BlockKey(key); err != nil {
		http.Error(w, "Failed to block key", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "ok",
	})
}

func (s *Server) UnblockHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var data map[string]string
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	key, ok := data["key"]
	if !ok || key == "" {
		http.Error(w, "Missing key", http.StatusBadRequest)
		return
	}

	if err := s.storage.UnblockKey(key); err != nil {
		http.Error(w, "Failed to unblock key", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "ok",
	})
}

func (s *Server) BlockedHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	keys, err := s.storage.GetBlockedKeys()
	if err != nil {
		http.Error(w, "Failed to get blocked keys", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"blocked": keys,
	})
}

func (s *Server) PingHandler(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("pong"))
}

func (s *Server) PluginsHandler(w http.ResponseWriter, r *http.Request) {
	plugins := []models.Plugin{
		{ID: "1", Name: "Тёмная тема Pro", Author: "void", Type: "theme", Price: "Бесплатно", Description: "Расширенная тёмная тема", Downloads: 156, Version: "1.0.0"},
		{ID: "2", Name: "Антиспам фильтр", Author: "0xTima", Type: "filter", Price: "299 ₽", Description: "Автоматическое удаление спама", Downloads: 89, Version: "2.1.0"},
		{ID: "3", Name: "Экспорт в PDF", Author: "user123", Type: "export", Price: "Бесплатно", Description: "Выгрузка чатов в PDF", Downloads: 34, Version: "1.0.0"},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"plugins": plugins,
	})
}

func (s *Server) AckHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var data map[string]string
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	messageID, ok := data["messageId"]
	if !ok || messageID == "" {
		http.Error(w, "Missing messageId", http.StatusBadRequest)
		return
	}

	if err := s.storage.MarkDelivered(messageID); err != nil {
		http.Error(w, "Failed to mark delivered", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "ok",
	})
}

// ============================================================
// 📱 FCM REGISTER
// ============================================================

func (s *Server) RegisterFCMHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var data map[string]string
	if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	userID, ok := data["userId"]
	if !ok || userID == "" {
		http.Error(w, "Missing userId", http.StatusBadRequest)
		return
	}

	token, ok := data["token"]
	if !ok || token == "" {
		http.Error(w, "Missing token", http.StatusBadRequest)
		return
	}

	if err := s.storage.SaveFCMToken(userID, token); err != nil {
		http.Error(w, "Failed to save token", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}
