package storage

import (
	"database/sql"
	"time"
	"veil-signal-server/internal/models"

	_ "github.com/mattn/go-sqlite3"
)

type SQLiteStorage struct {
	db *sql.DB
}

func NewSQLiteStorage(dbPath string) (*SQLiteStorage, error) {
	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return nil, err
	}

	// Создаем таблицы
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS messages (
			id TEXT PRIMARY KEY,
			from_id TEXT NOT NULL,
			to_id TEXT NOT NULL,
			chat_id TEXT NOT NULL,
			text TEXT NOT NULL,
			timestamp INTEGER NOT NULL,
			delivered BOOLEAN DEFAULT FALSE
		);
		CREATE INDEX IF NOT EXISTS idx_messages_to_id ON messages(to_id);
		CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp);

		CREATE TABLE IF NOT EXISTS blocked_keys (
			key TEXT PRIMARY KEY
		);
	`)
	if err != nil {
		return nil, err
	}

	// Включаем WAL для производительности
	_, err = db.Exec("PRAGMA journal_mode=WAL")
	if err != nil {
		return nil, err
	}

	return &SQLiteStorage{db: db}, nil
}

// ============================================================
// MESSAGES
// ============================================================

func (s *SQLiteStorage) SaveMessage(msg models.Message) error {
	_, err := s.db.Exec(
		`INSERT INTO messages (id, from_id, to_id, chat_id, text, timestamp, delivered)
		 VALUES (?, ?, ?, ?, ?, ?, ?)`,
		msg.ID, msg.From, msg.To, msg.ChatID, msg.Text, msg.Timestamp.UnixMilli(), false,
	)
	return err
}

func (s *SQLiteStorage) GetMessages(userID string) ([]models.Message, error) {
	rows, err := s.db.Query(
		`SELECT id, from_id, to_id, chat_id, text, timestamp, delivered
		 FROM messages WHERE to_id = ? ORDER BY timestamp ASC`,
		userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var messages []models.Message
	for rows.Next() {
		var msg models.Message
		var ts int64
		err := rows.Scan(&msg.ID, &msg.From, &msg.To, &msg.ChatID, &msg.Text, &ts, &msg.Delivered)
		if err != nil {
			return nil, err
		}
		msg.Timestamp = time.UnixMilli(ts)
		messages = append(messages, msg)
	}
	return messages, nil
}

func (s *SQLiteStorage) DeleteMessages(userID string) error {
	_, err := s.db.Exec(`DELETE FROM messages WHERE to_id = ?`, userID)
	return err
}

func (s *SQLiteStorage) MarkDelivered(messageID string) error {
	_, err := s.db.Exec(`UPDATE messages SET delivered = TRUE WHERE id = ?`, messageID)
	return err
}

func (s *SQLiteStorage) DeleteOldMessages(ttlSeconds int64) error {
	cutoff := time.Now().Add(-time.Duration(ttlSeconds) * time.Second).UnixMilli()
	_, err := s.db.Exec(`DELETE FROM messages WHERE timestamp < ?`, cutoff)
	return err
}

// ============================================================
// BLOCKING
// ============================================================

func (s *SQLiteStorage) BlockKey(key string) error {
	_, err := s.db.Exec(`INSERT OR IGNORE INTO blocked_keys (key) VALUES (?)`, key)
	return err
}

func (s *SQLiteStorage) UnblockKey(key string) error {
	_, err := s.db.Exec(`DELETE FROM blocked_keys WHERE key = ?`, key)
	return err
}

func (s *SQLiteStorage) IsBlocked(key string) (bool, error) {
	var count int
	err := s.db.QueryRow(`SELECT COUNT(*) FROM blocked_keys WHERE key = ?`, key).Scan(&count)
	return count > 0, err
}

func (s *SQLiteStorage) GetBlockedKeys() ([]string, error) {
	rows, err := s.db.Query(`SELECT key FROM blocked_keys`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var keys []string
	for rows.Next() {
		var key string
		if err := rows.Scan(&key); err != nil {
			return nil, err
		}
		keys = append(keys, key)
	}
	return keys, nil
}

// ============================================================
// FCM TOKENS
// ============================================================

func (s *SQLiteStorage) SaveFCMToken(userID, token string) error {
	// Создаём таблицу, если её нет
	_, err := s.db.Exec(`
		CREATE TABLE IF NOT EXISTS fcm_tokens (
			user_id TEXT PRIMARY KEY,
			token TEXT NOT NULL
		)
	`)
	if err != nil {
		return err
	}

	_, err = s.db.Exec(
		`INSERT OR REPLACE INTO fcm_tokens (user_id, token) VALUES (?, ?)`,
		userID, token,
	)
	return err
}

func (s *SQLiteStorage) GetFCMToken(userID string) (string, error) {
	var token string
	err := s.db.QueryRow(`SELECT token FROM fcm_tokens WHERE user_id = ?`, userID).Scan(&token)
	if err == sql.ErrNoRows {
		return "", nil
	}
	return token, err
}

func (s *SQLiteStorage) DeleteFCMToken(userID string) error {
	_, err := s.db.Exec(`DELETE FROM fcm_tokens WHERE user_id = ?`, userID)
	return err
}

// ============================================================
// WALLET
// ============================================================

func (s *SQLiteStorage) GetBalance(userID string) (float64, error) {
	// Создаём таблицу если нет
	s.db.Exec(`CREATE TABLE IF NOT EXISTS wallet (user_id TEXT PRIMARY KEY, balance REAL DEFAULT 0)`)

	var balance float64
	err := s.db.QueryRow(`SELECT balance FROM wallet WHERE user_id = ?`, userID).Scan(&balance)
	if err == sql.ErrNoRows {
		// Если пользователя нет, создаём с балансом 0
		_, insertErr := s.db.Exec(`INSERT INTO wallet (user_id, balance) VALUES (?, 0)`, userID)
		if insertErr != nil {
			return 0, insertErr
		}
		return 0, nil
	}
	return balance, err
}

func (s *SQLiteStorage) UpdateBalance(userID string, amount float64) error {
	// Создаём таблицу если нет
	s.db.Exec(`CREATE TABLE IF NOT EXISTS wallet (user_id TEXT PRIMARY KEY, balance REAL DEFAULT 0)`)

	result, err := s.db.Exec(
		`INSERT INTO wallet (user_id, balance) VALUES (?, ?)
		 ON CONFLICT(user_id) DO UPDATE SET balance = balance + ?`,
		userID, amount, amount,
	)
	if err != nil {
		return err
	}
	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		// Если не сработало, пробуем просто обновить
		_, err = s.db.Exec(`UPDATE wallet SET balance = balance + ? WHERE user_id = ?`, amount, userID)
		if err != nil {
			return err
		}
		// Проверяем, существует ли запись
		var count int
		s.db.QueryRow(`SELECT COUNT(*) FROM wallet WHERE user_id = ?`, userID).Scan(&count)
		if count == 0 {
			_, err = s.db.Exec(`INSERT INTO wallet (user_id, balance) VALUES (?, ?)`, userID, amount)
			return err
		}
	}
	return nil
}

// ============================================================
// TRANSACTIONS
// ============================================================

func (s *SQLiteStorage) SaveTransaction(tx models.Transaction) error {
	_, err := s.db.Exec(`
		CREATE TABLE IF NOT EXISTS transactions (
			id TEXT PRIMARY KEY,
			user_id TEXT NOT NULL,
			amount REAL NOT NULL,
			type TEXT NOT NULL,
			description TEXT,
			timestamp INTEGER NOT NULL,
			status TEXT NOT NULL,
			fee REAL DEFAULT 0,
			recipient TEXT,
			sender TEXT
		)
	`)
	if err != nil {
		return err
	}

	_, err = s.db.Exec(
		`INSERT INTO transactions (id, user_id, amount, type, description, timestamp, status, fee, recipient, sender)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		tx.ID, tx.UserID, tx.Amount, tx.Type, tx.Description,
		tx.Timestamp.UnixMilli(), tx.Status, tx.Fee, tx.Recipient, tx.Sender,
	)
	return err
}

func (s *SQLiteStorage) GetTransactions(userID string) ([]models.Transaction, error) {
	rows, err := s.db.Query(
		`SELECT id, user_id, amount, type, description, timestamp, status, fee, recipient, sender
		 FROM transactions WHERE user_id = ? ORDER BY timestamp DESC LIMIT 100`,
		userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var transactions []models.Transaction
	for rows.Next() {
		var tx models.Transaction
		var ts int64
		var fee sql.NullFloat64
		var recipient, sender sql.NullString

		err := rows.Scan(&tx.ID, &tx.UserID, &tx.Amount, &tx.Type, &tx.Description,
			&ts, &tx.Status, &fee, &recipient, &sender)
		if err != nil {
			return nil, err
		}
		tx.Timestamp = time.UnixMilli(ts)
		if fee.Valid {
			tx.Fee = fee.Float64
		}
		if recipient.Valid {
			tx.Recipient = recipient.String
		}
		if sender.Valid {
			tx.Sender = sender.String
		}
		transactions = append(transactions, tx)
	}
	return transactions, nil
}

// ============================================================
// GIFT CARDS
// ============================================================

func (s *SQLiteStorage) SaveGiftCard(card models.GiftCard) error {
	_, err := s.db.Exec(`
		CREATE TABLE IF NOT EXISTS gift_cards (
			id TEXT PRIMARY KEY,
			code TEXT UNIQUE NOT NULL,
			amount REAL NOT NULL,
			recipient TEXT NOT NULL,
			recipient_key TEXT,
			status TEXT NOT NULL,
			created_at INTEGER NOT NULL,
			used_at INTEGER
		)
	`)
	if err != nil {
		return err
	}

	_, err = s.db.Exec(
		`INSERT INTO gift_cards (id, code, amount, recipient, recipient_key, status, created_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?)`,
		card.ID, card.Code, card.Amount, card.Recipient, card.RecipientKey,
		card.Status, card.CreatedAt.UnixMilli(),
	)
	return err
}

func (s *SQLiteStorage) GetGiftCardByCode(code string) (models.GiftCard, error) {
	var card models.GiftCard
	var createdAt int64
	var usedAt sql.NullInt64
	var recipientKey sql.NullString

	err := s.db.QueryRow(
		`SELECT id, code, amount, recipient, recipient_key, status, created_at, used_at
		 FROM gift_cards WHERE code = ?`,
		code,
	).Scan(&card.ID, &card.Code, &card.Amount, &card.Recipient, &recipientKey,
		&card.Status, &createdAt, &usedAt)
	if err != nil {
		return card, err
	}

	card.CreatedAt = time.UnixMilli(createdAt)
	if usedAt.Valid {
		t := time.UnixMilli(usedAt.Int64)
		card.UsedAt = &t
	}
	if recipientKey.Valid {
		card.RecipientKey = recipientKey.String
	}
	return card, nil
}

func (s *SQLiteStorage) ActivateGiftCard(cardID, userID string, usedAt *time.Time) error {
	var ts int64
	if usedAt != nil {
		ts = usedAt.UnixMilli()
	}
	_, err := s.db.Exec(
		`UPDATE gift_cards SET status = 'used', used_at = ?, recipient_key = ?
		 WHERE id = ? AND status = 'active'`,
		ts, userID, cardID,
	)
	return err
}

// ============================================================
// CLOSE
// ============================================================

func (s *SQLiteStorage) Close() error {
	return s.db.Close()
}
