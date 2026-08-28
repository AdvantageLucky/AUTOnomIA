package visitas

import (
	"context"
	"testing"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"kigo-autonomia-backend/internal/platform/ctxkeys"
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

func TestGuardarAnalisisIA_ConCambioDeEstado(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	v := &Visita{
		TenantID: 1, Titular: "Juan", CasaDestino: "Casa 1",
		Estado: EstadoPendiente, KioskoID: 1,
		TipoVisitante: TipoVisitante("VISITANTE"), TipoDocumento: TipoDocumento("INE"),
	}
	if err := repo.Create(v); err != nil {
		t.Fatalf("no se pudo crear la visita: %v", err)
	}

	ctx := context.WithValue(context.Background(), ctxkeys.TenantID, uint(1))
	repoCtx := repo.WithContext(ctx)

	nuevoEstado := EstadoAprobado
	scoreJSON := []byte(`{"veces_visitado":2,"confiable":true}`)
	if err := repoCtx.GuardarAnalisisIA(v.ID, "resumen de prueba", scoreJSON, &nuevoEstado); err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}

	var found Visita
	db.First(&found, v.ID)
	if found.ResumenIA != "resumen de prueba" {
		t.Errorf("esperaba resumen_ia guardado, got %q", found.ResumenIA)
	}
	if string(found.ScoreIA) != string(scoreJSON) {
		t.Errorf("esperaba score_ia guardado, got %s", found.ScoreIA)
	}
	if found.Estado != EstadoAprobado {
		t.Errorf("esperaba estado APROBADO, got %s", found.Estado)
	}
	if found.AutorizadoPorTipo != AutorizadorAgente {
		t.Errorf("esperaba autorizado_por_tipo=AGENTE, got %q", found.AutorizadoPorTipo)
	}
}

func TestGuardarAnalisisIA_SinCambioDeEstado(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	v := &Visita{
		TenantID: 1, Titular: "Juan", CasaDestino: "Casa 1",
		Estado: EstadoPendiente, KioskoID: 1,
		TipoVisitante: TipoVisitante("VISITANTE"), TipoDocumento: TipoDocumento("INE"),
	}
	if err := repo.Create(v); err != nil {
		t.Fatalf("no se pudo crear la visita: %v", err)
	}

	ctx := context.WithValue(context.Background(), ctxkeys.TenantID, uint(1))
	repoCtx := repo.WithContext(ctx)

	scoreJSON := []byte(`{"veces_visitado":0}`)
	if err := repoCtx.GuardarAnalisisIA(v.ID, "aun analizando historial", scoreJSON, nil); err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}

	var found Visita
	db.First(&found, v.ID)
	if found.ResumenIA != "aun analizando historial" {
		t.Errorf("esperaba resumen_ia guardado, got %q", found.ResumenIA)
	}
	// El estado y autorizado_por_tipo NO deben tocarse cuando nuevoEstado es nil.
	if found.Estado != EstadoPendiente {
		t.Errorf("esperaba que el estado siguiera PENDIENTE, got %s", found.Estado)
	}
	if found.AutorizadoPorTipo != "" {
		t.Errorf("esperaba autorizado_por_tipo vacío, got %q", found.AutorizadoPorTipo)
	}
}
