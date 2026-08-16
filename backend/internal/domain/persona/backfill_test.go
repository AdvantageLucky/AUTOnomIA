package persona

import (
	"testing"

	"kigo-autonomia-backend/internal/domain/residente"

	"gorm.io/gorm"
)

func TestConstruirBackfill_UnResidenteConTelefono_CreaUnaPersonaYUnaMembresia(t *testing.T) {
	r := residente.Residente{
		Model:           gorm.Model{ID: 1},
		TenantID:        10,
		Telefono:        "5551234567",
		Nombre:          "Ana",
		ApellidoPaterno: "García",
		CasaDestino:     "Casa 12",
		Pin:             "$2a$10$hashfalso",
		Status:          residente.ResidenteStatusActivo,
	}

	resultado := ConstruirBackfill([]residente.Residente{r})

	if len(resultado.Personas) != 1 {
		t.Fatalf("esperaba 1 persona, got %d", len(resultado.Personas))
	}
	p := resultado.Personas[0]
	if p.Telefono != "5551234567" || p.Nombre != "Ana" || p.ApellidoPaterno != "García" {
		t.Errorf("persona no coincide con el residente original: %+v", p)
	}

	if len(resultado.Membresias) != 1 {
		t.Fatalf("esperaba 1 membresia, got %d", len(resultado.Membresias))
	}
	m := resultado.Membresias[0]
	if m.TenantID != 10 || m.CasaDestino != "Casa 12" || m.Pin != r.Pin {
		t.Errorf("membresia no coincide con el residente original: %+v", m)
	}

	if len(resultado.Omitidos) != 0 {
		t.Errorf("no esperaba omitidos, got %d", len(resultado.Omitidos))
	}
}

func TestConstruirBackfill_DosResidentesMismoTelefono_UnaSolaPersonaDosMembresias(t *testing.T) {
	telefono := "5559998877"
	r1 := residente.Residente{Model: gorm.Model{ID: 1}, TenantID: 10, Telefono: telefono, CasaDestino: "Casa 1", Pin: "hash1", Status: residente.ResidenteStatusActivo}
	r2 := residente.Residente{Model: gorm.Model{ID: 2}, TenantID: 20, Telefono: telefono, CasaDestino: "Casa 2", Pin: "hash2", Status: residente.ResidenteStatusActivo}

	resultado := ConstruirBackfill([]residente.Residente{r1, r2})

	if len(resultado.Personas) != 1 {
		t.Fatalf("esperaba 1 persona (mismo teléfono), got %d", len(resultado.Personas))
	}
	if len(resultado.Membresias) != 2 {
		t.Fatalf("esperaba 2 membresias, got %d", len(resultado.Membresias))
	}
	tenants := map[uint]bool{}
	for _, m := range resultado.Membresias {
		tenants[m.TenantID] = true
	}
	if !tenants[10] || !tenants[20] {
		t.Errorf("esperaba membresias en tenants 10 y 20, got %+v", resultado.Membresias)
	}
}

func TestConstruirBackfill_TelefonoVacio_SeOmiteYNoCreaPersona(t *testing.T) {
	r := residente.Residente{Model: gorm.Model{ID: 3}, TenantID: 10, Telefono: "", CasaDestino: "Casa 3"}

	resultado := ConstruirBackfill([]residente.Residente{r})

	if len(resultado.Personas) != 0 {
		t.Errorf("no esperaba personas, got %d", len(resultado.Personas))
	}
	if len(resultado.Membresias) != 0 {
		t.Errorf("no esperaba membresias, got %d", len(resultado.Membresias))
	}
	if len(resultado.Omitidos) != 1 || resultado.Omitidos[0].ID != 3 {
		t.Errorf("esperaba el residente #3 en omitidos, got %+v", resultado.Omitidos)
	}
}
