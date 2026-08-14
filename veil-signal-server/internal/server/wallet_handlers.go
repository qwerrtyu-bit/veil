package server

import (
	"encoding/json"
	"net/http"
	"time"

	"veil-signal-server/internal/models"

	"github.com/google/uuid"
)

// GetBalance - получить баланс пользователя
func (s *Server) GetBalanceHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID := r.URL.Query().Get("userId")
	if userID == "" {
		http.Error(w, "Missing userId", http.StatusBadRequest)
		return
	}

	balance, err := s.storage.GetBalance(userID)
	if err != nil {
		http.Error(w, "Failed to get balance", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"userId":  userID,
		"balance": balance,
	})
}

// GetTransactions - получить историю транзакций
func (s *Server) GetTransactionsHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID := r.URL.Query().Get("userId")
	if userID == "" {
		http.Error(w, "Missing userId", http.StatusBadRequest)
		return
	}

	transactions, err := s.storage.GetTransactions(userID)
	if err != nil {
		http.Error(w, "Failed to get transactions", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"transactions": transactions,
	})
}

// Transfer - перевод средств
func (s *Server) TransferHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req models.TransferRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	if req.From == "" || req.To == "" || req.Amount <= 0 {
		http.Error(w, "Invalid parameters", http.StatusBadRequest)
		return
	}

	// Проверяем баланс отправителя
	balance, err := s.storage.GetBalance(req.From)
	if err != nil {
		http.Error(w, "Failed to check balance", http.StatusInternalServerError)
		return
	}

	fee := 0.1
	totalAmount := req.Amount + fee

	if balance < totalAmount {
		http.Error(w, "Insufficient balance", http.StatusPaymentRequired)
		return
	}

	// Списываем с отправителя
	if err := s.storage.UpdateBalance(req.From, -totalAmount); err != nil {
		http.Error(w, "Failed to update sender balance", http.StatusInternalServerError)
		return
	}

	// Добавляем получателю
	if err := s.storage.UpdateBalance(req.To, req.Amount); err != nil {
		// Откат
		s.storage.UpdateBalance(req.From, totalAmount)
		http.Error(w, "Failed to update recipient balance", http.StatusInternalServerError)
		return
	}

	// Сохраняем транзакции
	txID := uuid.New().String()
	timestamp := time.Now()

	senderTx := models.Transaction{
		ID:          txID + "_out",
		UserID:      req.From,
		Amount:      totalAmount,
		Type:        "transfer",
		Description: req.Description,
		Timestamp:   timestamp,
		Status:      "completed",
		Fee:         fee,
		Recipient:   req.To,
	}

	recipientTx := models.Transaction{
		ID:          txID + "_in",
		UserID:      req.To,
		Amount:      req.Amount,
		Type:        "transfer",
		Description: req.Description,
		Timestamp:   timestamp,
		Status:      "completed",
		Sender:      req.From,
	}

	s.storage.SaveTransaction(senderTx)
	s.storage.SaveTransaction(recipientTx)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  "ok",
		"txId":    txID,
		"balance": balance - totalAmount,
	})
}

// CreateGiftCard - создать подарочную карту
func (s *Server) CreateGiftCardHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Amount    float64 `json:"amount"`
		Recipient string  `json:"recipient"`
		PublicKey string  `json:"publicKey,omitempty"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	if req.Amount <= 0 || req.Recipient == "" {
		http.Error(w, "Invalid parameters", http.StatusBadRequest)
		return
	}

	card := models.GiftCard{
		ID:           uuid.New().String(),
		Code:         generateGiftCardCode(),
		Amount:       req.Amount,
		Recipient:    req.Recipient,
		RecipientKey: req.PublicKey,
		Status:       "active",
		CreatedAt:    time.Now(),
	}

	if err := s.storage.SaveGiftCard(card); err != nil {
		http.Error(w, "Failed to save gift card", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "ok",
		"card":   card,
	})
}

// ActivateGiftCard - активировать подарочную карту
func (s *Server) ActivateGiftCardHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Code   string `json:"code"`
		UserID string `json:"userId"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	if req.Code == "" || req.UserID == "" {
		http.Error(w, "Missing code or userId", http.StatusBadRequest)
		return
	}

	card, err := s.storage.GetGiftCardByCode(req.Code)
	if err != nil {
		http.Error(w, "Card not found", http.StatusNotFound)
		return
	}

	if card.Status != "active" {
		http.Error(w, "Card already used or expired", http.StatusBadRequest)
		return
	}

	// Активируем карту
	now := time.Now()
	if err := s.storage.ActivateGiftCard(card.ID, req.UserID, &now); err != nil {
		http.Error(w, "Failed to activate card", http.StatusInternalServerError)
		return
	}

	// Пополняем баланс пользователя
	if err := s.storage.UpdateBalance(req.UserID, card.Amount); err != nil {
		http.Error(w, "Failed to update balance", http.StatusInternalServerError)
		return
	}

	// Сохраняем транзакцию
	tx := models.Transaction{
		ID:          uuid.New().String(),
		UserID:      req.UserID,
		Amount:      card.Amount,
		Type:        "deposit",
		Description: "Активация подарочной карты",
		Timestamp:   now,
		Status:      "completed",
	}
	s.storage.SaveTransaction(tx)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  "ok",
		"message": "Card activated successfully",
		"amount":  card.Amount,
	})
}

// generateGiftCardCode - генерация кода подарочной карты
func generateGiftCardCode() string {
	const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	result := make([]byte, 12)
	for i := range result {
		result[i] = chars[time.Now().UnixNano()%int64(len(chars))]
	}
	return string(result[:4]) + "-" + string(result[4:8]) + "-" + string(result[8:12])
}
