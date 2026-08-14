package models

import "time"

type Bot struct {
	ID             string    `json:"id"`
	Name           string    `json:"name"`
	Username       string    `json:"username"`
	Token          string    `json:"token"`
	OwnerPublicKey string    `json:"ownerPublicKey"`
	IsActive       bool      `json:"isActive"`
	WelcomeMessage string    `json:"welcomeMessage"`
	TotalMessages  int       `json:"totalMessages"`
	CreatedAt      time.Time `json:"createdAt"`
}

type BotMessage struct {
	ID        string    `json:"id"`
	BotID     string    `json:"botId"`
	ChatID    string    `json:"chatId"`
	Text      string    `json:"text"`
	From      string    `json:"from"`
	Timestamp time.Time `json:"timestamp"`
}
