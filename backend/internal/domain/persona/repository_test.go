package persona

import (
	"testing"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"kigo-autonomia-backend/internal/domain/residente"
)

func setupTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Fatalf("no se pudo abrir sqlite en memoria: %v", err)
	}
	if err := db.AutoMigrate(&Persona{}, &residente.Membresia{}); err != nil {
		t.Fatalf("no se pudo migrar: %v", err)
	}
	return db
}

func TestUpdateDeviceToken(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	p := &Persona{Telefono: "+525512345678"}
	if err := repo.Create(p); err != nil {
		t.Fatalf("no se pudo crear la persona: %v", err)
	}

	if err := repo.UpdateDeviceToken(p.ID, "token-abc"); err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}

	found, err := repo.FindByID(p.ID)
	if err != nil {
		t.Fatalf("no se pudo recargar la persona: %v", err)
	}
	if found.DeviceToken == nil || *found.DeviceToken != "token-abc" {
		t.Errorf("esperaba device_token='token-abc', got %+v", found.DeviceToken)
	}
}

func TestFindActivasPorCasaDestino(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	pActiva := &Persona{Telefono: "+525500000001"}
	repo.Create(pActiva)
	db.Create(&residente.Membresia{PersonaID: pActiva.ID, TenantID: 1, CasaDestino: "Casa 1", Status: "activo"})

	pPendiente := &Persona{Telefono: "+525500000002"}
	repo.Create(pPendiente)
	db.Create(&residente.Membresia{PersonaID: pPendiente.ID, TenantID: 1, CasaDestino: "Casa 1", Status: "pendiente"})

	pOtraCasa := &Persona{Telefono: "+525500000003"}
	repo.Create(pOtraCasa)
	db.Create(&residente.Membresia{PersonaID: pOtraCasa.ID, TenantID: 1, CasaDestino: "Casa 2", Status: "activo"})

	pOtroTenant := &Persona{Telefono: "+525500000004"}
	repo.Create(pOtroTenant)
	db.Create(&residente.Membresia{PersonaID: pOtroTenant.ID, TenantID: 2, CasaDestino: "Casa 1", Status: "activo"})

	lista, err := repo.FindActivasPorCasaDestino(1, "Casa 1")
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if len(lista) != 1 || lista[0].ID != pActiva.ID {
		t.Fatalf("esperaba solo la persona activa correcta, got %+v", lista)
	}
}
