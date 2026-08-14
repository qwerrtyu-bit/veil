package fcm

import (
	"context"
	"log"

	firebase "firebase.google.com/go"
	"firebase.google.com/go/messaging"
	"google.golang.org/api/option"
)

type FCMService struct {
	client *messaging.Client
}

func NewFCMService(serviceAccountPath string) (*FCMService, error) {
	opt := option.WithCredentialsFile(serviceAccountPath)
	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		return nil, err
	}

	client, err := app.Messaging(context.Background())
	if err != nil {
		return nil, err
	}

	log.Println("📱 FCM сервис инициализирован")
	return &FCMService{client: client}, nil
}

func (f *FCMService) SendNotification(token, title, body string) error {
	if token == "" {
		return nil
	}

	message := &messaging.Message{
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Token: token,
	}

	_, err := f.client.Send(context.Background(), message)
	if err != nil {
		log.Printf("⚠️ Ошибка отправки FCM: %v", err)
		return err
	}

	log.Printf("✅ Уведомление отправлено на токен: %s...", token[:8])
	return nil
}
