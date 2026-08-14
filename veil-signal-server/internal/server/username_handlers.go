package server

import (
	"encoding/json"
	"net/http"
	"strings"
)

func (s *Server) RegisterUsernameHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Username    string `json:"username"`
		OwnerType   string `json:"ownerType"`
		OwnerID     string `json:"ownerId"`
		DisplayName string `json:"displayName"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	if len(req.Username) < 3 || len(req.Username) > 32 {
		http.Error(w, "Username must be 3-32 characters", http.StatusBadRequest)
		return
	}

	if !strings.ContainsAny(req.Username, "abcdefghijklmnopqrstuvwxyz0123456789_") {
		http.Error(w, "Username can only contain letters, numbers and _", http.StatusBadRequest)
		return
	}

	existing, _ := s.storage.GetUsernameByUsername(req.Username)
	if existing != nil {
		http.Error(w, "Username already taken", http.StatusConflict)
		return
	}

	if err := s.storage.CreateUsername(req.Username, req.OwnerType, req.OwnerID, req.DisplayName); err != nil {
		http.Error(w, "Failed to register username", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":   "ok",
		"username": req.Username,
	})
}

func (s *Server) SearchUsernamesHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	query := r.URL.Query().Get("q")
	if query == "" {
		http.Error(w, "Missing query", http.StatusBadRequest)
		return
	}

	limit := 20
	results, err := s.storage.SearchUsernames(query, limit)
	if err != nil {
		http.Error(w, "Search failed", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"results": results,
	})
}

func (s *Server) GetUsernameHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	ownerID := r.URL.Query().Get("ownerId")
	if ownerID == "" {
		http.Error(w, "Missing ownerId", http.StatusBadRequest)
		return
	}

	username, err := s.storage.GetUsernameByOwner(ownerID)
	if err != nil {
		http.Error(w, "Failed to get username", http.StatusInternalServerError)
		return
	}

	if username == nil {
		http.Error(w, "Username not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(username)
}

func (s *Server) PurchaseUsernameHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Username  string `json:"username"`
		OwnerID   string `json:"ownerId"`
		OwnerType string `json:"ownerType"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	if req.Username == "" || req.OwnerID == "" {
		http.Error(w, "Missing required fields", http.StatusBadRequest)
		return
	}

	available, err := s.storage.IsUsernameAvailable(req.Username)
	if err != nil {
		http.Error(w, "Failed to check availability", http.StatusInternalServerError)
		return
	}
	if !available {
		http.Error(w, "Username not available", http.StatusConflict)
		return
	}

	price, tier, err := s.storage.GetUsernamePrice(req.Username)
	if err != nil {
		http.Error(w, "Failed to get price", http.StatusInternalServerError)
		return
	}

	if price == 0 {
		http.Error(w, "This username is free", http.StatusBadRequest)
		return
	}

	balance, err := s.storage.GetBalance(req.OwnerID)
	if err != nil {
		http.Error(w, "Failed to check balance", http.StatusInternalServerError)
		return
	}

	if balance < float64(price) {
		http.Error(w, "Insufficient balance", http.StatusPaymentRequired)
		return
	}

	if err := s.storage.PurchaseUsername(
		req.Username,
		req.OwnerType,
		req.OwnerID,
		req.Username,
		price,
		tier,
	); err != nil {
		http.Error(w, "Purchase failed: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":   "ok",
		"username": req.Username,
		"tier":     tier,
		"price":    price,
	})
}

func (s *Server) GetPremiumUsernamesHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	usernames, err := s.storage.GetPremiumUsernames()
	if err != nil {
		http.Error(w, "Failed to get premium usernames", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"available": usernames,
	})
}
