package persona

import (
	"testing"

	"kigo-autonomia-backend/internal/domain/invitaciones"
	"kigo-autonomia-backend/internal/domain/residente"
)

func TestResolverEstadoQR_MembresiaActiva(t *testing.T) {
	p := &Persona{Nombre: "Ana"}
	m := &residente.Membresia{CasaDestino: "Casa 5", PermiteReconocimientoFacial: true, Status: residente.ResidenteStatusActivo}

	r := ResolverEstadoQR(p, m, nil)

	if r.Estado != EstadoQRMiembro {
		t.Fatalf("esperaba %q, tuve %q", EstadoQRMiembro, r.Estado)
	}
	if r.CasaDestino != "Casa 5" || !r.PermiteReconocimientoFacial {
		t.Fatalf("no propagó los datos de la membresía: %+v", r)
	}
}

func TestResolverEstadoQR_MembresiaPendiente_NoCuentaComoActiva(t *testing.T) {
	p := &Persona{Nombre: "Ana"}
	m := &residente.Membresia{CasaDestino: "Casa 5", Status: residente.ResidenteStatusPendiente}

	r := ResolverEstadoQR(p, m, nil)

	if r.Estado == EstadoQRMiembro {
		t.Fatalf("una membresía pendiente no debe resolver como miembro activo")
	}
}

func TestResolverEstadoQR_InvitacionActiva_SinMembresia(t *testing.T) {
	p := &Persona{Nombre: "Luis"}
	destinoID := uint(7)
	inv := &invitaciones.Invitacion{DestinoID: destinoID, PermiteReconocimientoFacial: true}

	r := ResolverEstadoQR(p, nil, inv)

	if r.Estado != EstadoQRInvitado {
		t.Fatalf("esperaba %q, tuve %q", EstadoQRInvitado, r.Estado)
	}
	if r.DestinoID == nil || *r.DestinoID != destinoID {
		t.Fatalf("no propagó el destino de la invitación: %+v", r)
	}
}

func TestResolverEstadoQR_MembresiaActiva_TienePrioridadSobreInvitacion(t *testing.T) {
	p := &Persona{Nombre: "Ana"}
	m := &residente.Membresia{CasaDestino: "Casa 5", Status: residente.ResidenteStatusActivo}
	inv := &invitaciones.Invitacion{DestinoID: 7}

	r := ResolverEstadoQR(p, m, inv)

	if r.Estado != EstadoQRMiembro {
		t.Fatalf("una membresía activa debe ganarle a una invitación: %+v", r)
	}
}

func TestResolverEstadoQR_SinNadaEnEsteCentro(t *testing.T) {
	p := &Persona{Nombre: "Nuevo"}

	r := ResolverEstadoQR(p, nil, nil)

	if r.Estado != EstadoQRDesconocidoEnCentro {
		t.Fatalf("esperaba %q, tuve %q", EstadoQRDesconocidoEnCentro, r.Estado)
	}
}
