package visitas

import (
	"testing"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Fatalf("no se pudo abrir sqlite en memoria: %v", err)
	}
	if err := db.AutoMigrate(&Visita{}); err != nil {
		t.Fatalf("no se pudo migrar Visita: %v", err)
	}
	return db
}

func TestFindByClientID_NoExiste(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	v, err := repo.FindByClientID(1, "no-existe")
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if v != nil {
		t.Errorf("esperaba nil, got %+v", v)
	}
}

func TestFindByClientID_Existe(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	clientID := "abc-123"
	original := &Visita{
		TenantID: 1, Titular: "Juan", CasaDestino: "Casa 1",
		Estado: EstadoPendiente, KioskoID: 1, ClientID: &clientID,
		TipoVisitante: TipoVisitante("VISITANTE"), TipoDocumento: TipoDocumento("SIN_DOCUMENTO"),
	}
	if err := repo.Create(original); err != nil {
		t.Fatalf("no se pudo crear la visita: %v", err)
	}

	found, err := repo.FindByClientID(1, clientID)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if found == nil || found.ID != original.ID {
		t.Errorf("esperaba encontrar la visita %d, got %+v", original.ID, found)
	}
}

func TestFindByClientID_OtroTenantNoLaVe(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	clientID := "abc-123"
	original := &Visita{
		TenantID: 1, Titular: "Juan", CasaDestino: "Casa 1",
		Estado: EstadoPendiente, KioskoID: 1, ClientID: &clientID,
		TipoVisitante: TipoVisitante("VISITANTE"), TipoDocumento: TipoDocumento("SIN_DOCUMENTO"),
	}
	if err := repo.Create(original); err != nil {
		t.Fatalf("no se pudo crear la visita: %v", err)
	}

	found, err := repo.FindByClientID(2, clientID)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if found != nil {
		t.Errorf("esperaba nil (otro tenant), got %+v", found)
	}
}
