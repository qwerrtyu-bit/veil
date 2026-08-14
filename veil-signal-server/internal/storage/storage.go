package storage

import (
	"time"
	"veil-signal-server/internal/models"
)

type Storage interface {
	// ============================================================
	// MESSAGES
	// ============================================================
	SaveMessage(msg models.Message) error
	GetMessages(userID string) ([]models.Message, error)
	DeleteMessages(userID string) error
	MarkDelivered(messageID string) error
	DeleteOldMessages(ttlSeconds int64) error

	// ============================================================
	// BLOCKING
	// ============================================================
	BlockKey(key string) error
	UnblockKey(key string) error
	IsBlocked(key string) (bool, error)
	GetBlockedKeys() ([]string, error)

	// ============================================================
	// FCM TOKENS
	// ============================================================
	SaveFCMToken(userID, token string) error
	GetFCMToken(userID string) (string, error)
	DeleteFCMToken(userID string) error

	// ============================================================
	// WALLET
	// ============================================================
	GetBalance(userID string) (float64, error)
	UpdateBalance(userID string, amount float64) error
	SaveTransaction(tx models.Transaction) error
	GetTransactions(userID string) ([]models.Transaction, error)

	// ============================================================
	// GIFT CARDS
	// ============================================================
	SaveGiftCard(card models.GiftCard) error
	GetGiftCardByCode(code string) (models.GiftCard, error)
	ActivateGiftCard(cardID, userID string, usedAt *time.Time) error

	// ============================================================
	// BOTS
	// ============================================================
	CreateBot(name, username, ownerPublicKey, welcomeMessage string) (*models.Bot, error)
	GetBotByToken(token string) (*models.Bot, error)
	GetBotsByOwner(ownerKey string) ([]models.Bot, error)
	IncrementBotMessages(botID string) error
	ToggleBot(botID string) error
	DeleteBot(botID string) error

	// ============================================================
	// USERNAMES
	// ============================================================
	CreateUsername(username, ownerType, ownerID, displayName string) error
	GetUsernameByUsername(username string) (*models.Username, error)
	GetUsernameByOwner(ownerID string) (*models.Username, error)
	SearchUsernames(query string, limit int) ([]models.UsernameSearchResult, error)
	UpdateUsername(ownerID, newUsername string) error
	DeleteUsername(ownerID string) error

	// ============================================================
	// PREMIUM USERNAMES
	// ============================================================
	IsUsernameAvailable(username string) (bool, error)
	GetUsernamePrice(username string) (int, string, error)
	PurchaseUsername(username, ownerType, ownerID, displayName string, price int, tier string) error
	GetPremiumUsernames() ([]string, error)

	// ============================================================
	// CLOSE
	// ============================================================
	Close() error
}
