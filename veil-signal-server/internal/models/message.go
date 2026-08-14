package models

import "time"

type Message struct {
	ID        string    `json:"id"`
	From      string    `json:"from"`
	To        string    `json:"to"`
	ChatID    string    `json:"chatId"`
	Text      string    `json:"text"`
	Timestamp time.Time `json:"timestamp"`
	Delivered bool      `json:"delivered"`
}

type RegisterRequest struct {
	UserID string `json:"userId"`
}

type SendRequest struct {
	ID     string `json:"id"`
	From   string `json:"from"`
	To     string `json:"to"`
	ChatID string `json:"chatId"`
	Text   string `json:"text"`
}

type PollResponse struct {
	Messages []Message `json:"messages"`
	Blocked  bool      `json:"blocked,omitempty"`
}

type Plugin struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Author      string `json:"author"`
	Type        string `json:"type"`
	Price       string `json:"price"`
	Description string `json:"description"`
	Downloads   int    `json:"downloads"`
	Version     string `json:"version"`
}