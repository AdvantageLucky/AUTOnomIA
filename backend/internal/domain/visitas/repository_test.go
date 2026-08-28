package visitas

import (
	"context"
	"testing"
	"time"

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

func TestEstadisticasPorPersona_ConHistorial(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	personaID := uint(7)
	base := time.Now().Add(-72 * time.Hour)
	visitas := []*Visita{
		{TenantID: 1, Titular: "Ana", CasaDestino: "Casa 1", Estado: EstadoAprobado, KioskoID: 1, PersonaID: &personaID},
		{TenantID: 1, Titular: "Ana", CasaDestino: "Casa 1", Estado: EstadoAprobado, KioskoID: 1, PersonaID: &personaID},
		{TenantID: 1, Titular: "Ana", CasaDestino: "Casa 2", Estado: EstadoAprobado, KioskoID: 1, PersonaID: &personaID},
	}
	for i, v := range visitas {
		if err := repo.Create(v); err != nil {
			t.Fatalf("no se pudo crear la visita %d: %v", i, err)
		}
		// CreatedAt lo pone GORM al Create; lo desplazamos a mano para
		// poder distinguir "última visita" de forma determinista.
		db.Model(v).UpdateColumn("created_at", base.Add(time.Duration(i)*time.Hour))
	}

	ctx := context.WithValue(context.Background(), ctxkeys.TenantID, uint(1))
	repoCtx := repo.WithContext(ctx)

	stats, err := repoCtx.EstadisticasPorPersona(personaID)
	if err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}
	if stats.VecesVisitado != 3 {
		t.Errorf("esperaba VecesVisitado=3, got %d", stats.VecesVisitado)
	}
	if stats.CasaHabitual != "Casa 1" {
		t.Errorf("esperaba CasaHabitual='Casa 1' (2 de 3), got %q", stats.CasaHabitual)
	}
	if stats.UltimaVisita == nil {
		t.Fatal("esperaba UltimaVisita no nil")
	}
}

func TestEstadisticasPorPersona_SinHistorial(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	ctx := context.WithValue(context.Background(), ctxkeys.TenantID, uint(1))
	repoCtx := repo.WithContext(ctx)

	stats, err := repoCtx.EstadisticasPorPersona(999)
	if err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}
	if stats.VecesVisitado != 0 {
		t.Errorf("esperaba VecesVisitado=0, got %d", stats.VecesVisitado)
	}
	if stats.UltimaVisita != nil {
		t.Errorf("esperaba UltimaVisita nil, got %v", stats.UltimaVisita)
	}
}

func TestEstadisticasPorPersona_AislaPorTenant(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	personaID := uint(7)
	v := &Visita{TenantID: 2, Titular: "Ana", CasaDestino: "Casa 1", Estado: EstadoAprobado, KioskoID: 1, PersonaID: &personaID}
	if err := repo.Create(v); err != nil {
		t.Fatalf("no se pudo crear la visita: %v", err)
	}

	ctx := context.WithValue(context.Background(), ctxkeys.TenantID, uint(1))
	repoCtx := repo.WithContext(ctx)

	stats, err := repoCtx.EstadisticasPorPersona(personaID)
	if err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}
	if stats.VecesVisitado != 0 {
		t.Errorf("esperaba VecesVisitado=0 (la visita es de otro tenant), got %d", stats.VecesVisitado)
	}
}

// El historial del residente tiene que traer lo ya resuelto — es lo que
// distingue a esta consulta de FindPendientesByCasaDestino.
func TestFindHistorialByCasaDestino_IncluyeResueltas(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	crear := func(titular string, estado EstadoVisita, casa string, tenant uint) {
		v := &Visita{
			TenantID: tenant, Titular: titular, CasaDestino: casa, Estado: estado,
			KioskoID: 1, TipoVisitante: TipoVisitante("VISITANTE"),
			TipoDocumento: TipoDocumento("SIN_DOCUMENTO"),
		}
		if err := repo.Create(v); err != nil {
			t.Fatalf("no se pudo crear la visita %s: %v", titular, err)
		}
	}

	crear("Aprobada", EstadoAprobado, "Casa 4", 1)
	crear("Rechazada", EstadoRechazado, "casa 4", 1) // case-insensitive
	crear("Pendiente", EstadoPendiente, "Casa 4", 1)
	crear("Otra casa", EstadoAprobado, "Casa 9", 1)
	crear("Otro tenant", EstadoAprobado, "Casa 4", 2)

	list, total, err := repo.FindHistorialByCasaDestino(1, "CASA 4", 1, 30)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if total != 3 || len(list) != 3 {
		t.Fatalf("esperaba 3 visitas de la casa, got total=%d len=%d", total, len(list))
	}

	vistos := map[string]bool{}
	for _, v := range list {
		vistos[v.Titular] = true
	}
	for _, esperado := range []string{"Aprobada", "Rechazada", "Pendiente"} {
		if !vistos[esperado] {
			t.Errorf("falta %q en el historial: %v", esperado, vistos)
		}
	}
}

func TestFindHistorialByCasaDestino_Pagina(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	for i := 0; i < 5; i++ {
		v := &Visita{
			TenantID: 1, Titular: "V", CasaDestino: "Casa 4", Estado: EstadoAprobado,
			KioskoID: 1, TipoVisitante: TipoVisitante("VISITANTE"),
			TipoDocumento: TipoDocumento("SIN_DOCUMENTO"),
		}
		if err := repo.Create(v); err != nil {
			t.Fatalf("no se pudo crear: %v", err)
		}
	}

	list, total, err := repo.FindHistorialByCasaDestino(1, "Casa 4", 2, 2)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if total != 5 {
		t.Errorf("esperaba total=5, got %d", total)
	}
	if len(list) != 2 {
		t.Errorf("esperaba 2 en la pagina 2, got %d", len(list))
	}
}
