package storage

import (
	"database/sql"
	"errors"
	"time"
	"veil-signal-server/internal/models"
)

func (s *SQLiteStorage) CreateUsername(username, ownerType, ownerID, displayName string) error {
	_, err := s.db.Exec(`
		CREATE TABLE IF NOT EXISTS usernames (
			id TEXT PRIMARY KEY,
			username TEXT UNIQUE NOT NULL,
			owner_type TEXT NOT NULL,
			owner_id TEXT NOT NULL,
			display_name TEXT NOT NULL,
			is_active BOOLEAN DEFAULT TRUE,
			tier TEXT DEFAULT 'free',
			price INTEGER DEFAULT 0,
			purchased_at INTEGER,
			created_at INTEGER NOT NULL,
			updated_at INTEGER NOT NULL
		)
	`)
	if err != nil {
		return err
	}

	_, err = s.db.Exec(
		`INSERT INTO usernames (id, username, owner_type, owner_id, display_name, is_active, tier, price, purchased_at, created_at, updated_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		"usr_"+time.Now().Format("20060102150405"),
		username, ownerType, ownerID, displayName,
		true, "free", 0, time.Now().UnixMilli(),
		time.Now().UnixMilli(), time.Now().UnixMilli(),
	)
	return err
}

func (s *SQLiteStorage) GetUsernameByUsername(username string) (*models.Username, error) {
	var u models.Username
	var createdAt, updatedAt, purchasedAt int64
	var tier, price sql.NullString

	err := s.db.QueryRow(`
		SELECT id, username, owner_type, owner_id, display_name, is_active, tier, price, purchased_at, created_at, updated_at
		FROM usernames WHERE username = ?
	`, username).Scan(
		&u.ID, &u.Username, &u.OwnerType, &u.OwnerID,
		&u.DisplayName, &u.IsActive, &tier, &price,
		&purchasedAt, &createdAt, &updatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	u.CreatedAt = time.UnixMilli(createdAt)
	u.UpdatedAt = time.UnixMilli(updatedAt)
	if tier.Valid {
		u.Tier = tier.String
	}
	return &u, nil
}

func (s *SQLiteStorage) GetUsernameByOwner(ownerID string) (*models.Username, error) {
	var u models.Username
	var createdAt, updatedAt, purchasedAt int64
	var tier, price sql.NullString

	err := s.db.QueryRow(`
		SELECT id, username, owner_type, owner_id, display_name, is_active, tier, price, purchased_at, created_at, updated_at
		FROM usernames WHERE owner_id = ?
	`, ownerID).Scan(
		&u.ID, &u.Username, &u.OwnerType, &u.OwnerID,
		&u.DisplayName, &u.IsActive, &tier, &price,
		&purchasedAt, &createdAt, &updatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	u.CreatedAt = time.UnixMilli(createdAt)
	u.UpdatedAt = time.UnixMilli(updatedAt)
	if tier.Valid {
		u.Tier = tier.String
	}
	return &u, nil
}

func (s *SQLiteStorage) SearchUsernames(query string, limit int) ([]models.UsernameSearchResult, error) {
	rows, err := s.db.Query(`
		SELECT username, owner_type, owner_id, display_name, tier
		FROM usernames
		WHERE is_active = TRUE AND (username LIKE ? OR display_name LIKE ?)
		ORDER BY 
			CASE tier 
				WHEN 'legendary' THEN 1
				WHEN 'premium' THEN 2
				WHEN 'exclusive' THEN 3
				WHEN 'short' THEN 4
				ELSE 5
			END,
			username ASC
		LIMIT ?
	`, query+"%", query+"%", limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []models.UsernameSearchResult
	for rows.Next() {
		var r models.UsernameSearchResult
		var ownerType, tier string
		err := rows.Scan(&r.Username, &ownerType, &r.OwnerID, &r.DisplayName, &tier)
		if err != nil {
			return nil, err
		}
		r.OwnerType = ownerType
		r.IsBot = ownerType == "bot"
		r.Tier = tier
		results = append(results, r)
	}
	return results, nil
}

func (s *SQLiteStorage) UpdateUsername(ownerID, newUsername string) error {
	_, err := s.db.Exec(
		`UPDATE usernames SET username = ?, updated_at = ? WHERE owner_id = ?`,
		newUsername, time.Now().UnixMilli(), ownerID,
	)
	return err
}

func (s *SQLiteStorage) DeleteUsername(ownerID string) error {
	_, err := s.db.Exec(`DELETE FROM usernames WHERE owner_id = ?`, ownerID)
	return err
}

// ============================================================
// PREMIUM USERNAMES
// ============================================================

func (s *SQLiteStorage) IsUsernameAvailable(username string) (bool, error) {
	var count int
	err := s.db.QueryRow(`SELECT COUNT(*) FROM usernames WHERE username = ?`, username).Scan(&count)
	if err != nil {
		return false, err
	}
	return count == 0, nil
}

func (s *SQLiteStorage) GetUsernamePrice(username string) (int, string, error) {
	length := len(username)
	if length >= 5 {
		return 0, "free", nil
	}

	switch length {
	case 4:
		return 1000, "short", nil
	case 3:
		return 5000, "exclusive", nil
	case 2:
		return 25000, "premium", nil
	case 1:
		return 100000, "legendary", nil
	default:
		return 0, "free", nil
	}
}

func (s *SQLiteStorage) PurchaseUsername(username, ownerType, ownerID, displayName string, price int, tier string) error {
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// Проверяем что юзернейм свободен
	var count int
	err = tx.QueryRow(`SELECT COUNT(*) FROM usernames WHERE username = ?`, username).Scan(&count)
	if err != nil {
		return err
	}
	if count > 0 {
		return errors.New("username already taken")
	}

	// Создаём запись
	_, err = tx.Exec(`
		INSERT INTO usernames (id, username, owner_type, owner_id, display_name, is_active, tier, price, purchased_at, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	`,
		"usr_"+time.Now().Format("20060102150405"),
		username, ownerType, ownerID, displayName,
		true, tier, price, time.Now().UnixMilli(),
		time.Now().UnixMilli(), time.Now().UnixMilli(),
	)
	if err != nil {
		return err
	}

	// Создаём таблицу wallet если нет
	_, err = tx.Exec(`
		CREATE TABLE IF NOT EXISTS wallet (
			user_id TEXT PRIMARY KEY,
			balance REAL DEFAULT 0
		)
	`)
	if err != nil {
		return err
	}

	// Списываем VLC с баланса
	result, err := tx.Exec(
		`UPDATE wallet SET balance = balance - ? WHERE user_id = ? AND balance >= ?`,
		price, ownerID, price,
	)
	if err != nil {
		return err
	}
	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		return errors.New("insufficient balance or user not found")
	}

	return tx.Commit()
}

func (s *SQLiteStorage) GetPremiumUsernames() ([]string, error) {
	rows, err := s.db.Query(`
		SELECT username FROM usernames 
		WHERE tier != 'free' 
		ORDER BY 
			CASE tier 
				WHEN 'legendary' THEN 1
				WHEN 'premium' THEN 2
				WHEN 'exclusive' THEN 3
				WHEN 'short' THEN 4
			END,
			username ASC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var usernames []string
	for rows.Next() {
		var username string
		if err := rows.Scan(&username); err != nil {
			return nil, err
		}
		usernames = append(usernames, username)
	}
	return usernames, nil
}
