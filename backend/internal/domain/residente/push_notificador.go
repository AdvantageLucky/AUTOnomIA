package residente

import (
	"context"
	"log"

	"kigo-autonomia-backend/internal/domain/visitas"
)

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
