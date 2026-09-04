package residente

import (
	"testing"

	"kigo-autonomia-backend/internal/domain/destinos"

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
	FotoIneUrl      string
	Embedding       FloatArray `gorm:"type:text"`
}

func (testPersona) TableName() string { return "personas" }

func setupMembresiaTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Fatalf("no se pudo abrir sqlite en memoria: %v", err)
	}
	if err := db.AutoMigrate(&testPersona{}, &Membresia{}, &destinos.Destino{}); err != nil {
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

// Caso reportado: el dashboard no sabía quién había enrolado a un invitado
// frecuente -- CreadaPorPersonaID se llena solo para esas membresías.
func TestFindActivasPorTenant_EnroladoPorNombre(t *testing.T) {
	db := setupMembresiaTestDB(t)
	repo := NewMembresiaRepository(db)

	residente := testPersona{Nombre: "Ana", ApellidoPaterno: "Ruiz", Telefono: "+525500000001"}
	db.Create(&residente)
	db.Create(&Membresia{PersonaID: residente.ID, TenantID: 1, CasaDestino: "Casa 1", Status: ResidenteStatusActivo, Rol: RolResidente})

	invitado := testPersona{Nombre: "Beto", ApellidoPaterno: "Soto", Telefono: "+525500000002"}
	db.Create(&invitado)
	residenteID := residente.ID
	db.Create(&Membresia{
		PersonaID: invitado.ID, TenantID: 1, CasaDestino: "Casa 1", Status: ResidenteStatusActivo,
		Rol: RolInvitadoFrecuente, CreadaPorPersonaID: &residenteID,
	})

	list, err := repo.FindActivasPorTenant(1)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if len(list) != 2 {
		t.Fatalf("esperaba 2 membresías, got %d", len(list))
	}

	var residenteFila, invitadoFila *MembresiaActivaConPersona
	for i := range list {
		if list[i].Rol == RolInvitadoFrecuente {
			invitadoFila = &list[i]
		} else {
			residenteFila = &list[i]
		}
	}
	if invitadoFila == nil || invitadoFila.EnroladoPorNombre != "Ana Ruiz" {
		t.Errorf("esperaba EnroladoPorNombre 'Ana Ruiz' para el invitado frecuente, got %+v", invitadoFila)
	}
	if residenteFila == nil || residenteFila.EnroladoPorNombre != "" {
		t.Errorf("esperaba EnroladoPorNombre vacío para el residente real, got %+v", residenteFila)
	}
}

// TestRevocarPorTenant_NoAfectaOtroTenant es el caso de seguridad que
// importa: un admin del tenant 1 nunca debe poder revocar (ni por error de
// id, ni por lote) una membresía que pertenece al tenant 2.
func TestRevocarPorTenant_NoAfectaOtroTenant(t *testing.T) {
	db := setupMembresiaTestDB(t)
	repo := NewMembresiaRepository(db)

	p1 := testPersona{Nombre: "Ana", Telefono: "+525500000001"}
	db.Create(&p1)
	m1 := Membresia{PersonaID: p1.ID, TenantID: 1, CasaDestino: "Casa 1", Status: ResidenteStatusActivo}
	db.Create(&m1)

	p2 := testPersona{Nombre: "Beto", Telefono: "+525500000002"}
	db.Create(&p2)
	m2 := Membresia{PersonaID: p2.ID, TenantID: 2, CasaDestino: "Casa 2", Status: ResidenteStatusActivo}
	db.Create(&m2)

	afectadas, err := repo.RevocarPorTenant(1, []uint{m1.ID, m2.ID})
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if afectadas != 1 {
		t.Fatalf("esperaba revocar solo 1 membresía (la del tenant 1), got %d", afectadas)
	}

	activasT2, err := repo.FindActivasPorTenant(2)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if len(activasT2) != 1 {
		t.Fatalf("la membresía del tenant 2 no debía revocarse, quedaron %d activas", len(activasT2))
	}

	activasT1, err := repo.FindActivasPorTenant(1)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if len(activasT1) != 0 {
		t.Fatalf("esperaba 0 membresías activas en tenant 1 tras revocar, got %d", len(activasT1))
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
