package models

import "time"

type Username struct {
	ID          string    `json:"id"`
	Username    string    `json:"username"`
	OwnerType   string    `json:"ownerType"`
	OwnerID     string    `json:"ownerId"`
	DisplayName string    `json:"displayName"`
	IsActive    bool      `json:"isActive"`
	Tier        string    `json:"tier"`  // "free", "short", "exclusive", "premium"
	Price       int       `json:"price"` // цена в VLC
	PurchasedAt time.Time `json:"purchasedAt"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

type UsernameSearchResult struct {
	Username    string `json:"username"`
	OwnerType   string `json:"ownerType"`
	OwnerID     string `json:"ownerId"`
	DisplayName string `json:"displayName"`
	IsBot       bool   `json:"isBot"`
	Tier        string `json:"tier"`
}

type UsernamePurchaseRequest struct {
	Username  string `json:"username"`
	OwnerID   string `json:"ownerId"`
	OwnerType string `json:"ownerType"`
}
