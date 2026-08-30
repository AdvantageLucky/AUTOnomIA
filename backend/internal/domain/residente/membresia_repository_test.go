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
	ApellidoMaterno string
	Curp            string
	Telefono        string
	FotoCaraUrl     string
	Embedding       FloatArray `gorm:"type:text"`
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
	// FindActivasPorTenant devuelve el nombre de pila solo (sin concatenar
	// apellidos) — el dashboard arma el nombre completo por su cuenta con
	// nombre + apellido_paterno + apellido_materno (ver app.js).
	if list[0].Nombre != "Ana" {
		t.Errorf("esperaba nombre 'Ana', got %q", list[0].Nombre)
	}
	if list[0].CasaDestino != "Casa 1" {
		t.Errorf("esperaba casa 'Casa 1', got %q", list[0].CasaDestino)
	}
}

func TestFindCompanerosCasa(t *testing.T) {
	db := setupMembresiaTestDB(t)
	repo := NewMembresiaRepository(db)

	titular := testPersona{Nombre: "Ana", ApellidoPaterno: "Ruiz", Telefono: "+525500000001"}
	db.Create(&titular)
	db.Create(&Membresia{PersonaID: titular.ID, TenantID: 1, CasaDestino: "Casa 1", Status: ResidenteStatusActivo})

	familiar := testPersona{Nombre: "Beto", ApellidoPaterno: "Ruiz", Telefono: "+525500000002"}
	db.Create(&familiar)
	db.Create(&Membresia{PersonaID: familiar.ID, TenantID: 1, CasaDestino: "casa 1", Status: ResidenteStatusActivo})

	pendiente := testPersona{Nombre: "Cin", ApellidoPaterno: "Diaz", Telefono: "+525500000003"}
	db.Create(&pendiente)
	db.Create(&Membresia{PersonaID: pendiente.ID, TenantID: 1, CasaDestino: "Casa 1", Status: ResidenteStatusPendiente})

	otraCasa := testPersona{Nombre: "Dan", ApellidoPaterno: "Soto", Telefono: "+525500000004"}
	db.Create(&otraCasa)
	db.Create(&Membresia{PersonaID: otraCasa.ID, TenantID: 1, CasaDestino: "Casa 2", Status: ResidenteStatusActivo})

	otroTenant := testPersona{Nombre: "Eva", ApellidoPaterno: "Vega", Telefono: "+525500000005"}
	db.Create(&otroTenant)
	db.Create(&Membresia{PersonaID: otroTenant.ID, TenantID: 2, CasaDestino: "Casa 1", Status: ResidenteStatusActivo})

	// Consulta como si fuera "titular" viendo sus compañeros de casa —
	// se excluye a sí mismo, incluye al familiar (case-insensitive "casa 1"
	// vs "Casa 1"), excluye al pendiente, a la otra casa y al otro tenant.
	list, err := repo.FindCompanerosCasa(1, "Casa 1", titular.ID)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if len(list) != 1 {
		t.Fatalf("esperaba 1 compañero de casa, got %d: %+v", len(list), list)
	}
	if list[0].NombreCompleto != "Beto Ruiz" {
		t.Errorf("esperaba 'Beto Ruiz', got %q", list[0].NombreCompleto)
	}
}

func TestFindCompanerosCasa_ListaVacia(t *testing.T) {
	db := setupMembresiaTestDB(t)
	repo := NewMembresiaRepository(db)

	titular := testPersona{Nombre: "Ana", ApellidoPaterno: "Ruiz", Telefono: "+525500000001"}
	db.Create(&titular)
	db.Create(&Membresia{PersonaID: titular.ID, TenantID: 1, CasaDestino: "Casa 1", Status: ResidenteStatusActivo})

	list, err := repo.FindCompanerosCasa(1, "Casa 1", titular.ID)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if len(list) != 0 {
		t.Fatalf("esperaba lista vacía (único en la casa), got %d", len(list))
	}
}
