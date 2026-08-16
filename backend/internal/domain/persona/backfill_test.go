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

	if len(resultado.Grupos) != 1 {
		t.Fatalf("esperaba 1 grupo, got %d", len(resultado.Grupos))
	}
	grupo := resultado.Grupos[0]
	if grupo.Persona.Telefono != "5551234567" || grupo.Persona.Nombre != "Ana" || grupo.Persona.ApellidoPaterno != "García" {
		t.Errorf("persona no coincide con el residente original: %+v", grupo.Persona)
	}

	if len(grupo.Membresias) != 1 {
		t.Fatalf("esperaba 1 membresia, got %d", len(grupo.Membresias))
	}
	m := grupo.Membresias[0]
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

	if len(resultado.Grupos) != 1 {
		t.Fatalf("esperaba 1 grupo (mismo teléfono), got %d", len(resultado.Grupos))
	}
	membresias := resultado.Grupos[0].Membresias
	if len(membresias) != 2 {
		t.Fatalf("esperaba 2 membresias, got %d", len(membresias))
	}
	tenants := map[uint]bool{}
	for _, m := range membresias {
		tenants[m.TenantID] = true
	}
	if !tenants[10] || !tenants[20] {
		t.Errorf("esperaba membresias en tenants 10 y 20, got %+v", membresias)
	}
}

func TestConstruirBackfill_TelefonoVacio_SeOmiteYNoCreaPersona(t *testing.T) {
	r := residente.Residente{Model: gorm.Model{ID: 3}, TenantID: 10, Telefono: "", CasaDestino: "Casa 3"}

	resultado := ConstruirBackfill([]residente.Residente{r})

	if len(resultado.Grupos) != 0 {
		t.Errorf("no esperaba grupos, got %d", len(resultado.Grupos))
	}
	if len(resultado.Omitidos) != 1 || resultado.Omitidos[0].ID != 3 {
		t.Errorf("esperaba el residente #3 en omitidos, got %+v", resultado.Omitidos)
	}
}

func TestConstruirBackfill_SoloElPrimeroSinRostro_UsaElEmbeddingDelSegundo(t *testing.T) {
	embedding := residente.FloatArray{0.1, 0.2, 0.3}
	r1 := residente.Residente{Model: gorm.Model{ID: 1}, TenantID: 10, Telefono: "5551112222", CasaDestino: "Casa 1", Pin: "hash1", Status: residente.ResidenteStatusActivo}
	r2 := residente.Residente{Model: gorm.Model{ID: 2}, TenantID: 20, Telefono: "5551112222", CasaDestino: "Casa 2", Pin: "hash2", Status: residente.ResidenteStatusActivo, Embedding: embedding, FotoCaraUrl: "caras/2.jpg"}

	resultado := ConstruirBackfill([]residente.Residente{r1, r2})

	if len(resultado.Grupos) != 1 {
		t.Fatalf("esperaba 1 grupo, got %d", len(resultado.Grupos))
	}
	p := resultado.Grupos[0].Persona
	if p.Embedding == nil {
		t.Fatal("esperaba que el embedding del segundo residente se usara, quedó nil")
	}
	if p.FotoCaraUrl != "caras/2.jpg" {
		t.Errorf("esperaba foto_cara_url del residente que aportó el embedding, got %q", p.FotoCaraUrl)
	}
}

func TestConstruirBackfill_DosResidentesMismoTelefonoYTenant_SegundoSeOmite(t *testing.T) {
	r1 := residente.Residente{Model: gorm.Model{ID: 1}, TenantID: 10, Telefono: "5553334444", CasaDestino: "Casa 1", Pin: "hash1", Status: residente.ResidenteStatusActivo}
	r2 := residente.Residente{Model: gorm.Model{ID: 2}, TenantID: 10, Telefono: "5553334444", CasaDestino: "Casa 1", Pin: "hash2", Status: residente.ResidenteStatusActivo}

	resultado := ConstruirBackfill([]residente.Residente{r1, r2})

	if len(resultado.Grupos) != 1 {
		t.Fatalf("esperaba 1 grupo, got %d", len(resultado.Grupos))
	}
	if len(resultado.Grupos[0].Membresias) != 1 {
		t.Fatalf("esperaba 1 membresia (mismo tenant+telefono), got %d", len(resultado.Grupos[0].Membresias))
	}
	if len(resultado.Omitidos) != 1 || resultado.Omitidos[0].ID != 2 {
		t.Errorf("esperaba al residente #2 en omitidos por duplicado, got %+v", resultado.Omitidos)
	}
}

func TestConstruirBackfill_TelefonosConFormatoDistinto_SeAgrupanJuntos(t *testing.T) {
	r1 := residente.Residente{Model: gorm.Model{ID: 1}, TenantID: 10, Telefono: "55 1234 5678", CasaDestino: "Casa 1", Pin: "hash1", Status: residente.ResidenteStatusActivo}
	r2 := residente.Residente{Model: gorm.Model{ID: 2}, TenantID: 20, Telefono: "5512345678", CasaDestino: "Casa 2", Pin: "hash2", Status: residente.ResidenteStatusActivo}

	resultado := ConstruirBackfill([]residente.Residente{r1, r2})

	if len(resultado.Grupos) != 1 {
		t.Fatalf("esperaba 1 grupo (mismo teléfono, distinto formato), got %d", len(resultado.Grupos))
	}
	if resultado.Grupos[0].Persona.Telefono != "5512345678" {
		t.Errorf("esperaba teléfono normalizado a solo dígitos, got %q", resultado.Grupos[0].Persona.Telefono)
	}
	if len(resultado.Grupos[0].Membresias) != 2 {
		t.Fatalf("esperaba 2 membresias (tenants distintos), got %d", len(resultado.Grupos[0].Membresias))
	}
}
