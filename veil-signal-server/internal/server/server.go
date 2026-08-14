package server

import (
	"sync"
	"time"
	"veil-signal-server/internal/config"
	"veil-signal-server/internal/fcm"
	"veil-signal-server/internal/storage"
)

type Server struct {
	storage    storage.Storage
	config     *config.Config
	fcm        *fcm.FCMService // <-- ДОБАВЛЕНО
	mu         sync.RWMutex
	requestLog map[string][]time.Time
}

func NewServer(storage storage.Storage, config *config.Config, fcm *fcm.FCMService) *Server {
	return &Server{
		storage:    storage,
		config:     config,
		fcm:        fcm,
		requestLog: make(map[string][]time.Time),
	}
}
