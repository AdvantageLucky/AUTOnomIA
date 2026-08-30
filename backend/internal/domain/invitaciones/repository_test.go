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
