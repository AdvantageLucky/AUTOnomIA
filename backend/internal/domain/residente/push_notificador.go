package residente

import (
	"context"
	"log"

	"kigo-autonomia-backend/internal/domain/visitas"
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

// PushNotificador implementa visitas.Notificador: busca a los residentes de
// la casa destino de una visita y les manda un push a cada dispositivo
// registrado.
type PushNotificador struct {
	repo   *Repository
	sender PushSender
}

func NewPushNotificador(repo *Repository, sender PushSender) *PushNotificador {
	return &PushNotificador{repo: repo, sender: sender}
}

func (n *PushNotificador) NotificarNuevaVisita(
	ctx context.Context,
	tenantID uint,
	casaDestino string,
	v visitas.Visita,
) error {
	residentes, err := n.repo.FindActivosPorCasaDestino(tenantID, casaDestino)
	if err != nil {
		return err
	}

	titulo := "Nueva solicitud de acceso"
	cuerpo := v.Titular + " quiere entrar a tu casa"

	for _, r := range conDeviceToken(residentes) {
		if err := n.sender.Send(ctx, *r.DeviceToken, titulo, cuerpo); err != nil {
			log.Printf("PushNotificador: error mandando a residente %d: %v", r.ID, err)
		}
	}
	return nil
}

// conDeviceToken filtra los residentes que sí tienen un token de dispositivo
// registrado y no vacío.
func conDeviceToken(residentes []Residente) []Residente {
	con := make([]Residente, 0, len(residentes))
	for _, r := range residentes {
		if r.DeviceToken != nil && *r.DeviceToken != "" {
			con = append(con, r)
		}
	}
	return con
}
