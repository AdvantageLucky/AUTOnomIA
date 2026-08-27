package residente

import (
	"context"
	"log"
)

// PushSender manda una notificación push a un dispositivo. Punto de
// integración con FCM real — ver LogPushSender para el estado actual
// (pendiente de credenciales de Firebase, ver memoria del proyecto).
type PushSender interface {
	Send(ctx context.Context, deviceToken, titulo, cuerpo string) error
}

// LogPushSender es un PushSender falso que solo loguea — se usa mientras no
// exista un proyecto de Firebase configurado para Kigo/AUTOnomIA.
type LogPushSender struct{}

func (LogPushSender) Send(_ context.Context, deviceToken, titulo, cuerpo string) error {
	log.Printf("[push-fake] a %s: %s — %s", deviceToken, titulo, cuerpo)
	return nil
}
