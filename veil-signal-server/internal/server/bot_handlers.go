package server

import (
	"encoding/json"
	"net/http"
	"time"
	"veil-signal-server/internal/models"

	"github.com/google/uuid"
)

func (s *Server) BotMessageHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Token  string `json:"token"`
		ChatID string `json:"chatId"`
		Text   string `json:"text"`
		From   string `json:"from"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	bot, err := s.storage.GetBotByToken(req.Token)
	if err != nil || bot == nil {
		http.Error(w, "Invalid bot token", http.StatusUnauthorized)
		return
	}

	if !bot.IsActive {
		http.Error(w, "Bot is disabled", http.StatusForbidden)
		return
	}

	msg := models.Message{
		ID:        uuid.New().String(),
		From:      bot.ID,
		To:        req.From,
		ChatID:    req.ChatID,
		Text:      req.Text,
		Timestamp: time.Now(),
		Delivered: false,
	}

	if err := s.storage.SaveMessage(msg); err != nil {
		http.Error(w, "Failed to save message", http.StatusInternalServerError)
		return
	}

	s.storage.IncrementBotMessages(bot.ID)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  "ok",
		"message": "Message sent",
	})
}

func (s *Server) GetBotsHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	ownerKey := r.URL.Query().Get("owner")
	if ownerKey == "" {
		http.Error(w, "Missing owner", http.StatusBadRequest)
		return
	}

	bots, err := s.storage.GetBotsByOwner(ownerKey)
	if err != nil {
		http.Error(w, "Failed to get bots", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"bots": bots,
	})
}

func (s *Server) CreateBotHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Name           string `json:"name"`
		Username       string `json:"username"`
		OwnerPublicKey string `json:"ownerPublicKey"`
		WelcomeMessage string `json:"welcomeMessage"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	if req.Name == "" || req.Username == "" || req.OwnerPublicKey == "" {
		http.Error(w, "Missing required fields", http.StatusBadRequest)
		return
	}

	bot, err := s.storage.CreateBot(req.Name, req.Username, req.OwnerPublicKey, req.WelcomeMessage)
	if err != nil {
		http.Error(w, "Failed to create bot", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "ok",
		"bot":    bot,
	})
}
