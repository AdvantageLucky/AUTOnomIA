package residente

import (
	"context"
	"fmt"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

// FirebasePushSender manda pushes reales vía Firebase Cloud Messaging.
type FirebasePushSender struct {
	client *messaging.Client
}

// NewFirebasePushSender abre el cliente de FCM a partir de la credencial de
// cuenta de servicio (Firebase Console → Configuración del proyecto →
// Cuentas de servicio → Generar nueva clave privada). El JSON nunca va al
// repo — se referencia por ruta vía FIREBASE_CREDENTIALS_PATH.
func NewFirebasePushSender(ctx context.Context, credentialsPath string) (*FirebasePushSender, error) {
	app, err := firebase.NewApp(ctx, nil, option.WithCredentialsFile(credentialsPath))
	if err != nil {
		return nil, fmt.Errorf("inicializando app de firebase: %w", err)
	}
	client, err := app.Messaging(ctx)
	if err != nil {
		return nil, fmt.Errorf("obteniendo cliente de messaging: %w", err)
	}
	return &FirebasePushSender{client: client}, nil
}

func (s *FirebasePushSender) Send(ctx context.Context, deviceToken, titulo, cuerpo string) error {
	_, err := s.client.Send(ctx, &messaging.Message{
		Token: deviceToken,
		Notification: &messaging.Notification{
			Title: titulo,
			Body:  cuerpo,
		},
	})
	return err
}
