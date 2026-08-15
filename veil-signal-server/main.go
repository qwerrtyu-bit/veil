package main

import (
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"veil-signal-server/internal/config"
	"veil-signal-server/internal/fcm"
	"veil-signal-server/internal/server"
	"veil-signal-server/internal/storage"

	"github.com/joho/godotenv"
)

func main() {
	// Загружаем .env файл
	if err := godotenv.Load(); err != nil {
		log.Println("⚠️ .env файл не найден, используем стандартные настройки")
	}

	cfg := config.Load()

	// Создаем папку для данных если её нет
	if err := os.MkdirAll("data", 0755); err != nil {
		log.Fatalf("Failed to create data directory: %v", err)
	}

	// Инициализация хранилища
	store, err := storage.NewSQLiteStorage(cfg.DBPath)
	if err != nil {
		log.Fatalf("Failed to initialize storage: %v", err)
	}
	defer store.Close()

	log.Printf("📊 База данных: %s", cfg.DBPath)

	// ═══════════════════════════════════════════════════════
	// 📱 ИНИЦИАЛИЗАЦИЯ FCM (для push-уведомлений)
	// ═══════════════════════════════════════════════════════
	var fcmService *fcm.FCMService

	// Получаем путь к ключу из переменной окружения
	keyPath := os.Getenv("FIREBASE_KEY_PATH")
	if keyPath == "" {
		keyPath = "firebase-adminsdk.json" // fallback
	}

	// Логируем путь для отладки
	log.Printf("🔍 Ищем ключ по пути: %s", keyPath)

	// Проверяем, есть ли файл ключа
	if _, err := os.Stat(keyPath); err == nil {
		fcmService, err = fcm.NewFCMService(keyPath)
		if err != nil {
			log.Printf("⚠️ FCM не инициализирован: %v", err)
		} else {
			log.Println("📱 FCM сервис инициализирован")
		}
	} else {
		log.Printf("⚠️ Файл ключа не найден по пути: %s", keyPath)
		log.Printf("💡 Убедитесь, что файл существует и путь указан правильно")
	}

	// Запуск фоновой очистки старых сообщений
	go func() {
		ticker := time.NewTicker(1 * time.Hour)
		defer ticker.Stop()
		for range ticker.C {
			if err := store.DeleteOldMessages(cfg.TTLSeconds); err != nil {
				log.Printf("⚠️ Ошибка очистки старых сообщений: %v", err)
			} else {
				log.Printf("🧹 Очистка старых сообщений выполнена (TTL: %d сек)", cfg.TTLSeconds)
			}
		}
	}()

	// Создание сервера
	srv := server.NewServer(store, cfg, fcmService)

	// HTTP маршруты
	http.HandleFunc("/register", corsMiddleware(srv.RegisterHandler))
	http.HandleFunc("/send", corsMiddleware(srv.SendHandler))
	http.HandleFunc("/poll", corsMiddleware(srv.PollHandler))
	http.HandleFunc("/block", corsMiddleware(srv.BlockHandler))
	http.HandleFunc("/unblock", corsMiddleware(srv.UnblockHandler))
	http.HandleFunc("/blocked", corsMiddleware(srv.BlockedHandler))
	http.HandleFunc("/ping", corsMiddleware(srv.PingHandler))
	http.HandleFunc("/plugins", corsMiddleware(srv.PluginsHandler))
	http.HandleFunc("/ack", corsMiddleware(srv.AckHandler))
	http.HandleFunc("/fcm/register", corsMiddleware(srv.RegisterFCMHandler))

	// ============================================================
	// WALLET
	// ============================================================
	http.HandleFunc("/wallet/balance", corsMiddleware(srv.GetBalanceHandler))
	http.HandleFunc("/wallet/transactions", corsMiddleware(srv.GetTransactionsHandler))
	http.HandleFunc("/wallet/transfer", corsMiddleware(srv.TransferHandler))

	// ============================================================
	// GIFT CARDS
	// ============================================================
	http.HandleFunc("/giftcard/create", corsMiddleware(srv.CreateGiftCardHandler))
	http.HandleFunc("/giftcard/activate", corsMiddleware(srv.ActivateGiftCardHandler))

	// ============================================================
	// USERNAMES
	// ============================================================
	http.HandleFunc("/username/register", corsMiddleware(srv.RegisterUsernameHandler))
	http.HandleFunc("/username/search", corsMiddleware(srv.SearchUsernamesHandler))
	http.HandleFunc("/username/get", corsMiddleware(srv.GetUsernameHandler))
	http.HandleFunc("/username/purchase", corsMiddleware(srv.PurchaseUsernameHandler))
	http.HandleFunc("/username/premium", corsMiddleware(srv.GetPremiumUsernamesHandler))

	// ============================================================
	// BOTS
	// ============================================================
	http.HandleFunc("/bots", corsMiddleware(srv.GetBotsHandler))
	http.HandleFunc("/bots/create", corsMiddleware(srv.CreateBotHandler))
	http.HandleFunc("/bots/message", corsMiddleware(srv.BotMessageHandler))

	// WebSocket
	ws := server.NewWebSocketServer(srv)
	http.HandleFunc("/ws", ws.HandleWS)

	// Запуск сервера
	log.Printf("🟢 Veil Signal Server запущен на порту %s", cfg.Port)
	log.Printf("🌐 WebSocket: ws://localhost:%s/ws", cfg.Port)
	log.Printf("📡 HTTP: http://localhost:%s", cfg.Port)

	// Graceful shutdown
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		if err := http.ListenAndServe(":"+cfg.Port, nil); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	<-stop
	log.Println("🛑 Сервер остановлен")
}

// CORS middleware
func corsMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		next(w, r)
	}
}
