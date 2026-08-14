package storage

import (
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"time"
	"veil-signal-server/internal/models"
)

func (s *SQLiteStorage) CreateBot(name, username, ownerPublicKey, welcomeMessage string) (*models.Bot, error) {
	tokenBytes := make([]byte, 32)
	if _, err := rand.Read(tokenBytes); err != nil {
		return nil, err
	}
	token := "veil_bot_" + hex.EncodeToString(tokenBytes)

	_, err := s.db.Exec(`
		CREATE TABLE IF NOT EXISTS bots (
			id TEXT PRIMARY KEY,
			name TEXT NOT NULL,
			username TEXT UNIQUE NOT NULL,
			token TEXT UNIQUE NOT NULL,
			owner_public_key TEXT NOT NULL,
			is_active BOOLEAN DEFAULT TRUE,
			welcome_message TEXT,
			total_messages INTEGER DEFAULT 0,
			created_at INTEGER NOT NULL
		)
	`)
	if err != nil {
		return nil, err
	}

	bot := &models.Bot{
		ID:             "bot_" + time.Now().Format("20060102150405"),
		Name:           name,
		Username:       username,
		Token:          token,
		OwnerPublicKey: ownerPublicKey,
		IsActive:       true,
		WelcomeMessage: welcomeMessage,
		TotalMessages:  0,
		CreatedAt:      time.Now(),
	}

	_, err = s.db.Exec(
		`INSERT INTO bots (id, name, username, token, owner_public_key, is_active, welcome_message, total_messages, created_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		bot.ID, bot.Name, bot.Username, bot.Token,
		bot.OwnerPublicKey, bot.IsActive, bot.WelcomeMessage,
		bot.TotalMessages, bot.CreatedAt.UnixMilli(),
	)
	if err != nil {
		return nil, err
	}

	return bot, nil
}

func (s *SQLiteStorage) GetBotByToken(token string) (*models.Bot, error) {
	var bot models.Bot
	var createdAt int64
	var welcomeMsg sql.NullString

	err := s.db.QueryRow(`
		SELECT id, name, username, token, owner_public_key, is_active, welcome_message, total_messages, created_at
		FROM bots WHERE token = ?
	`, token).Scan(
		&bot.ID, &bot.Name, &bot.Username, &bot.Token,
		&bot.OwnerPublicKey, &bot.IsActive, &welcomeMsg,
		&bot.TotalMessages, &createdAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	if welcomeMsg.Valid {
		bot.WelcomeMessage = welcomeMsg.String
	}
	bot.CreatedAt = time.UnixMilli(createdAt)

	return &bot, nil
}

func (s *SQLiteStorage) GetBotsByOwner(ownerKey string) ([]models.Bot, error) {
	rows, err := s.db.Query(`
		SELECT id, name, username, token, owner_public_key, is_active, welcome_message, total_messages, created_at
		FROM bots WHERE owner_public_key = ? ORDER BY created_at DESC
	`, ownerKey)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var bots []models.Bot
	for rows.Next() {
		var bot models.Bot
		var createdAt int64
		var welcomeMsg sql.NullString

		err := rows.Scan(
			&bot.ID, &bot.Name, &bot.Username, &bot.Token,
			&bot.OwnerPublicKey, &bot.IsActive, &welcomeMsg,
			&bot.TotalMessages, &createdAt,
		)
		if err != nil {
			return nil, err
		}

		if welcomeMsg.Valid {
			bot.WelcomeMessage = welcomeMsg.String
		}
		bot.CreatedAt = time.UnixMilli(createdAt)
		bots = append(bots, bot)
	}

	return bots, nil
}

func (s *SQLiteStorage) IncrementBotMessages(botID string) error {
	_, err := s.db.Exec(
		`UPDATE bots SET total_messages = total_messages + 1 WHERE id = ?`,
		botID,
	)
	return err
}

func (s *SQLiteStorage) ToggleBot(botID string) error {
	_, err := s.db.Exec(
		`UPDATE bots SET is_active = NOT is_active WHERE id = ?`,
		botID,
	)
	return err
}

func (s *SQLiteStorage) DeleteBot(botID string) error {
	_, err := s.db.Exec(`DELETE FROM bots WHERE id = ?`, botID)
	return err
}
