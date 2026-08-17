package persona

import (
	"kigo-autonomia-backend/internal/domain/invitaciones"
	"kigo-autonomia-backend/internal/domain/residente"
)

type EstadoQR string

const (
	// EstadoQRMiembro: la Persona tiene una Membresia activa en este tenant.
	EstadoQRMiembro EstadoQR = "miembro"
	// EstadoQRInvitado: sin membresía activa, pero con una invitación activa en este tenant.
	EstadoQRInvitado EstadoQR = "invitado"
	// EstadoQRDesconocidoEnCentro: la Persona existe en Kigo pero nunca ha estado en este tenant.
	EstadoQRDesconocidoEnCentro EstadoQR = "desconocido_en_centro"
)

// ResolucionQR es lo que el kiosko necesita para decidir qué pantalla
// mostrar tras escanear un QR — ver spec 2026-08-16-persona-identidad-kigo-design.md §5.
type ResolucionQR struct {
	Estado                      EstadoQR
	Nombre                      string
	CasaDestino                 string
	DestinoID                   *uint
	PermiteReconocimientoFacial bool
	InvitacionID                *uint
}

// ResolverEstadoQR es una función pura: dada una Persona ya identificada
// (firma del QR verificada) y lo que se encontró en DB para el tenant
// actual (membresía y/o invitación, cualquiera puede ser nil), decide cuál
// de las 3 ramas de §5 aplica. Una Membresia activa siempre gana sobre una
// invitación — ya es "de la casa", no una visita puntual.
func ResolverEstadoQR(p *Persona, m *residente.Membresia, inv *invitaciones.Invitacion) ResolucionQR {
	if m != nil && m.Status == residente.ResidenteStatusActivo {
		return ResolucionQR{
			Estado:                      EstadoQRMiembro,
			Nombre:                      p.Nombre,
			CasaDestino:                 m.CasaDestino,
			PermiteReconocimientoFacial: m.PermiteReconocimientoFacial,
		}
	}

	if inv != nil {
		destinoID := inv.DestinoID
		var invID *uint
		if inv.ID != 0 {
			id := inv.ID
			invID = &id
		}
		return ResolucionQR{
			Estado:                      EstadoQRInvitado,
			Nombre:                      p.Nombre,
			DestinoID:                   &destinoID,
			PermiteReconocimientoFacial: inv.PermiteReconocimientoFacial,
			InvitacionID:                invID,
		}
	}

	return ResolucionQR{
		Estado: EstadoQRDesconocidoEnCentro,
		Nombre: p.Nombre,
	}
}
