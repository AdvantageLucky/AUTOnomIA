package persona

import (
	"context"
	"log"

	"kigo-autonomia-backend/internal/domain/residente"
	"kigo-autonomia-backend/internal/domain/visitas"
)

// PushNotificador implementa visitas.Notificador resolviendo destinatarios
// vía Persona/Membresia — reemplaza a residente.PushNotificador para este
// flujo (Residente ya no se llena para altas nuevas, ver spec 2026-08-26).
// Reusa residente.PushSender/LogPushSender/FirebasePushSender sin cambios.
type PushNotificador struct {
	repo   *Repository
	sender residente.PushSender
}

func NewPushNotificador(repo *Repository, sender residente.PushSender) *PushNotificador {
	return &PushNotificador{repo: repo, sender: sender}
}

func (n *PushNotificador) NotificarNuevaVisita(
	ctx context.Context,
	tenantID uint,
	casaDestino string,
	v visitas.Visita,
) error {
	personas, err := n.repo.FindActivasPorCasaDestino(tenantID, casaDestino)
	if err != nil {
		return err
	}

	titulo := "Nueva solicitud de acceso"
	cuerpo := v.Titular + " quiere entrar a tu casa"

	for _, p := range conDeviceToken(personas) {
		if err := n.sender.Send(ctx, *p.DeviceToken, titulo, cuerpo); err != nil {
			log.Printf("PushNotificador: error mandando a persona %d: %v", p.ID, err)
		}
	}
	return nil
}

func conDeviceToken(personas []Persona) []Persona {
	con := make([]Persona, 0, len(personas))
	for _, p := range personas {
		if p.DeviceToken != nil && *p.DeviceToken != "" {
			con = append(con, p)
		}
	}
	return con
}
