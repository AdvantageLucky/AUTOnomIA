package persona

import (
	"context"
	"fmt"
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
	mailer EmailSender
}

func NewPushNotificador(repo *Repository, sender residente.PushSender, mailer EmailSender) *PushNotificador {
	return &PushNotificador{repo: repo, sender: sender, mailer: mailer}
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

	destinatarios := conDeviceToken(personas)
	titulo := "Nueva solicitud de acceso"
	cuerpo := v.Titular + " quiere entrar a tu casa"

	data := map[string]string{"tipo": "solicitud_pendiente"}
	for _, p := range destinatarios {
		if err := n.sender.Send(ctx, *p.DeviceToken, titulo, cuerpo, data); err != nil {
			log.Printf("PushNotificador: error mandando a persona %d: %v", p.ID, err)
		}
	}

	// Todo tipo de solicitud avisa al admin por correo, no solo cuando nadie
	// recibió el push -- el admin quiere enterarse de cada visita nueva sin
	// depender de tener el dashboard abierto (spec pedida 2026-09-02).
	n.avisarAdmin(ctx, tenantID, casaDestino, v, len(destinatarios) == 0)
	return nil
}

func (n *PushNotificador) avisarAdmin(ctx context.Context, tenantID uint, casaDestino string, v visitas.Visita, sinResidente bool) {
	if n.mailer == nil {
		return
	}
	correos, err := n.repo.CorreosAdminsDeTenant(tenantID)
	if err != nil {
		log.Printf("PushNotificador: error buscando admins del tenant %d: %v", tenantID, err)
		return
	}
	asunto := "Nueva solicitud de acceso"
	cuerpo := fmt.Sprintf("%s llegó a %q y espera autorización.\nRevisa la solicitud en el dashboard.", v.Titular, casaDestino)
	if sinResidente {
		asunto = "Visita sin residente al que avisar"
		cuerpo = fmt.Sprintf(
			"%s llegó a %q y no hay ningún residente enlazado a ese destino (o ninguno con la app instalada) para avisarle.\nRevisa la solicitud en el dashboard.",
			v.Titular, casaDestino,
		)
	}
	for _, correo := range correos {
		if correo == "" {
			continue
		}
		if err := n.mailer.Enviar(ctx, correo, asunto, cuerpo); err != nil {
			log.Printf("PushNotificador: error mandando correo a %s: %v", correo, err)
		}
	}
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
