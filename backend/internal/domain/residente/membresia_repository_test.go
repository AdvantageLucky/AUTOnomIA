package residente

import (
	"testing"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// testPersona replica solo las columnas de personas que consume el JOIN de
// FindActivasPorTenant/FindPendientesPorTenant — no se puede importar el
// paquete persona real aquí (persona ya importa residente; importarlo de
// vuelta crearía un ciclo).
type testPersona struct {
	ID              uint
	Nombre          string
	ApellidoPaterno string
	Telefono        string
}

func (testPersona) TableName() string { return "personas" }

func setupMembresiaTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Fatalf("no se pudo abrir sqlite en memoria: %v", err)
	}
	if err := db.AutoMigrate(&testPersona{}, &Membresia{}); err != nil {
		t.Fatalf("no se pudo migrar: %v", err)
	}
	return db
}

func TestFindActivasPorTenant(t *testing.T) {
	db := setupMembresiaTestDB(t)
	repo := NewMembresiaRepository(db)

	pActiva := testPersona{Nombre: "Ana", ApellidoPaterno: "Ruiz", Telefono: "+525500000001"}
	db.Create(&pActiva)
	db.Create(&Membresia{PersonaID: pActiva.ID, TenantID: 1, CasaDestino: "Casa 1", Status: ResidenteStatusActivo})

	pPendiente := testPersona{Nombre: "Beto", ApellidoPaterno: "Soto", Telefono: "+525500000002"}
	db.Create(&pPendiente)
	db.Create(&Membresia{PersonaID: pPendiente.ID, TenantID: 1, CasaDestino: "Casa 2", Status: ResidenteStatusPendiente})

	pOtroTenant := testPersona{Nombre: "Cin", ApellidoPaterno: "Diaz", Telefono: "+525500000003"}
	db.Create(&pOtroTenant)
	db.Create(&Membresia{PersonaID: pOtroTenant.ID, TenantID: 2, CasaDestino: "Casa 3", Status: ResidenteStatusActivo})

	list, err := repo.FindActivasPorTenant(1)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if len(list) != 1 {
		t.Fatalf("esperaba 1 membresía activa del tenant 1, got %d", len(list))
	}
	if list[0].Nombre != "Ana Ruiz" {
		t.Errorf("esperaba nombre 'Ana Ruiz', got %q", list[0].Nombre)
	}
	if list[0].CasaDestino != "Casa 1" {
		t.Errorf("esperaba casa 'Casa 1', got %q", list[0].CasaDestino)
	}
}
