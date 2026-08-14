package models

import "time"

type WalletBalance struct {
	UserID    string    `json:"userId"`
	Balance   float64   `json:"balance"`
	UpdatedAt time.Time `json:"updatedAt"`
}

type Transaction struct {
	ID          string    `json:"id"`
	UserID      string    `json:"userId"`
	Amount      float64   `json:"amount"`
	Type        string    `json:"type"`
	Description string    `json:"description"`
	Timestamp   time.Time `json:"timestamp"`
	Status      string    `json:"status"`
	Fee         float64   `json:"fee,omitempty"`
	Recipient   string    `json:"recipient,omitempty"`
	Sender      string    `json:"sender,omitempty"`
}

type TransferRequest struct {
	From        string  `json:"from"`
	To          string  `json:"to"`
	Amount      float64 `json:"amount"`
	Description string  `json:"description,omitempty"`
}

type GiftCard struct {
	ID           string     `json:"id"`
	Code         string     `json:"code"`
	Amount       float64    `json:"amount"`
	Recipient    string     `json:"recipient"`
	RecipientKey string     `json:"recipientKey,omitempty"`
	Status       string     `json:"status"`
	CreatedAt    time.Time  `json:"createdAt"`
	UsedAt       *time.Time `json:"usedAt,omitempty"`
}
