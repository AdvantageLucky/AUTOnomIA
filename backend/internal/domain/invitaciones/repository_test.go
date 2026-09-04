package invitaciones

import (
	"testing"
	"time"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupTestDB(t *testing.T) *gorm.DB {
	dbName := "file:" + t.Name() + "?mode=memory&cache=shared"
	db, err := gorm.Open(sqlite.Open(dbName), &gorm.Config{})
	if err != nil {
		t.Fatalf("no se pudo abrir sqlite en memoria: %v", err)
	}
	sqlDB, err := db.DB()
	if err == nil {
		sqlDB.SetMaxOpenConns(1)
	}
	if err := db.AutoMigrate(&Invitacion{}); err != nil {
		t.Fatalf("no se pudo migrar Invitacion: %v", err)
	}
	return db
}

func TestFindActivasNoExpiradasByTenant(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	futuro := time.Now().Add(24 * time.Hour)
	pasado := time.Now().Add(-24 * time.Hour)
	maxUsosAgotado := 1

	db.Create(&Invitacion{TenantID: 1, Token: "activa-sin-expirar", Titular: "A", ResidenteID: 1, DestinoID: 1})
	db.Create(&Invitacion{TenantID: 1, Token: "activa-expira-futuro", Titular: "B", ResidenteID: 1, DestinoID: 1, ExpiresAt: &futuro})
	db.Create(&Invitacion{TenantID: 1, Token: "ya-expirada", Titular: "C", ResidenteID: 1, DestinoID: 1, ExpiresAt: &pasado})
	db.Create(&Invitacion{TenantID: 1, Token: "usos-agotados", Titular: "D", ResidenteID: 1, DestinoID: 1, MaxUsos: &maxUsosAgotado, ConteoUsos: 1})
	db.Create(&Invitacion{TenantID: 2, Token: "otro-tenant", Titular: "E", ResidenteID: 1, DestinoID: 1})

	lista, err := repo.FindActivasNoExpiradasByTenant(1)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if len(lista) != 2 {
		t.Fatalf("esperaba 2 invitaciones activas, got %d: %+v", len(lista), lista)
	}
	tokens := map[string]bool{}
	for _, inv := range lista {
		tokens[inv.Token] = true
	}
	if !tokens["activa-sin-expirar"] || !tokens["activa-expira-futuro"] {
		t.Errorf("faltan tokens esperados en %+v", tokens)
	}
}

// Caso reportado: quien recibe una invitación no tenía forma de quitarla de
// su propia lista sin afectar a quien la creó.
func TestOcultarParaInvitado(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	personaID := uint(1)
	inv := &Invitacion{TenantID: 1, Token: "para-ocultar", Titular: "A", ResidenteID: 1, DestinoID: 1, PersonaInvitadaID: &personaID}
	if err := db.Create(inv).Error; err != nil {
		t.Fatalf("no se pudo crear la invitacion: %v", err)
	}

	lista, err := repo.FindByPersonaInvitada(personaID)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if len(lista) != 1 {
		t.Fatalf("esperaba 1 invitacion antes de ocultar, got %d", len(lista))
	}

	if err := repo.OcultarParaInvitado(inv.ID, personaID); err != nil {
		t.Fatalf("no esperaba error al ocultar, got %v", err)
	}

	lista, err = repo.FindByPersonaInvitada(personaID)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if len(lista) != 0 {
		t.Errorf("esperaba 0 invitaciones tras ocultar, got %d", len(lista))
	}
}

// Nadie mas que el propio invitado puede ocultarsela.
func TestOcultarParaInvitado_OtraPersonaNoPuede(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	personaID := uint(1)
	inv := &Invitacion{TenantID: 1, Token: "de-otro", Titular: "A", ResidenteID: 1, DestinoID: 1, PersonaInvitadaID: &personaID}
	if err := db.Create(inv).Error; err != nil {
		t.Fatalf("no se pudo crear la invitacion: %v", err)
	}

	err := repo.OcultarParaInvitado(inv.ID, uint(2))
	if err == nil {
		t.Fatal("esperaba error al intentar ocultar la invitacion de otra persona")
	}

	lista, err := repo.FindByPersonaInvitada(personaID)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if len(lista) != 1 {
		t.Errorf("la invitacion no debio ocultarse, got %d", len(lista))
	}
}
