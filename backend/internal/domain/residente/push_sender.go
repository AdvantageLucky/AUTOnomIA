package residente

import (
	"context"
	"log"
)

// PushSender manda una notificación push a un dispositivo. Punto de
// integración con FCM real — ver LogPushSender para el estado actual
// (pendiente de credenciales de Firebase, ver memoria del proyecto).
//
// data viaja como el payload "data" de FCM (nunca se muestra, solo lo lee el
// código de la app) -- kigo-app lo usa para decidir a dónde navegar cuando
// la persona toca la notificación (ver PushService en kigo-app), ya que
// notification.title/body no le dan al cliente ninguna forma de distinguir
// "te invitaron" de "tu invitación se usó" de "alguien espera en la puerta".
type PushSender interface {
	Send(ctx context.Context, deviceToken, titulo, cuerpo string, data map[string]string) error
}

// LogPushSender es un PushSender falso que solo loguea — se usa mientras no
// exista un proyecto de Firebase configurado para Kigo/AUTOnomIA.
type LogPushSender struct{}

func (LogPushSender) Send(_ context.Context, deviceToken, titulo, cuerpo string, data map[string]string) error {
	log.Printf("[push-fake] a %s: %s — %s (data=%v)", deviceToken, titulo, cuerpo, data)
	return nil
}
