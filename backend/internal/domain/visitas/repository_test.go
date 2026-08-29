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
	if err := repoCtx.GuardarAnalisisIA(v.ID, "resumen de prueba", scoreJSON, &nuevoEstado, true); err != nil {
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
	if !found.Intervenida {
		t.Errorf("esperaba intervenida=true, got false")
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
	if err := repoCtx.GuardarAnalisisIA(v.ID, "aun analizando historial", scoreJSON, nil, false); err != nil {
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
	if found.Intervenida {
		t.Errorf("esperaba intervenida=false (no se paso true), got true")
	}
}

func TestGuardarAnalisisIA_IntervenidaNoSeReseteaAFalse(t *testing.T) {
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

	// Primera llamada: marca intervenida=true (fue a revision).
	estadoRevision := EstadoRevision
	if err := repoCtx.GuardarAnalisisIA(v.ID, "resumen 1", []byte(`{}`), &estadoRevision, true); err != nil {
		t.Fatalf("no esperaba error en la primera llamada: %v", err)
	}

	// Segunda llamada hipotetica sobre la misma visita, con intervenida=false
	// (ej. un reanalisis que ya no detecto la anomalia) -- no debe borrar el
	// historial de que SI fue intervenida alguna vez.
	if err := repoCtx.GuardarAnalisisIA(v.ID, "resumen 2", []byte(`{}`), nil, false); err != nil {
		t.Fatalf("no esperaba error en la segunda llamada: %v", err)
	}

	var found Visita
	db.First(&found, v.ID)
	if !found.Intervenida {
		t.Errorf("esperaba que intervenida siguiera true tras la segunda llamada, got false")
	}
	if found.ResumenIA != "resumen 2" {
		t.Errorf("esperaba que resumen_ia se actualizara a 'resumen 2', got %q", found.ResumenIA)
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

// El historial responde "que resolvi yo": lo que esa Persona aprobo o rechazo
// desde la app. Todo lo demas que pasa en la misma casa queda fuera, incluido
// lo que resolvieron los otros miembros del domicilio.
func TestFindHistorialResueltasPorPersona_SoloLoDeEsaPersona(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	var yo, otroResidente uint = 10, 11

	crear := func(titular string, estado EstadoVisita, autorizador string, quien *uint, tenant uint) {
		v := &Visita{
			TenantID: tenant, Titular: titular, CasaDestino: "Casa 4", Estado: estado,
			AutorizadoPorTipo: autorizador, AutorizadoPorPersonaID: quien, KioskoID: 1,
			TipoVisitante: TipoVisitante("VISITANTE"),
			TipoDocumento: TipoDocumento("SIN_DOCUMENTO"),
		}
		if err := repo.Create(v); err != nil {
			t.Fatalf("no se pudo crear la visita %s: %v", titular, err)
		}
	}
	mia := &yo

	// Lo mio: aprobado y rechazado cuentan por igual.
	crear("La aprobe yo", EstadoAprobado, AutorizadorResidente, mia, 1)
	crear("La rechace yo", EstadoRechazado, AutorizadorResidente, mia, 1)

	// Todo lo que debe quedar fuera.
	crear("La aprobo otro residente", EstadoAprobado, AutorizadorResidente, &otroResidente, 1)
	crear("Sigue pendiente", EstadoPendiente, "", nil, 1)
	crear("La aprobo el admin", EstadoAprobado, AutorizadorAdmin, nil, 1)
	crear("La aprobo el agente", EstadoAprobado, AutorizadorAgente, nil, 1)
	crear("La escalo el sistema", EstadoRevision, AutorizadorSistema, nil, 1)
	crear("Otro tenant", EstadoAprobado, AutorizadorResidente, mia, 2)

	list, total, err := repo.FindHistorialResueltasPorPersona(1, yo, 1, 30)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if total != 2 || len(list) != 2 {
		t.Fatalf("esperaba 2 visitas mias, got total=%d len=%d", total, len(list))
	}
	for _, v := range list {
		if v.AutorizadoPorPersonaID == nil || *v.AutorizadoPorPersonaID != yo {
			t.Errorf("se colo %q, resuelta por %v", v.Titular, v.AutorizadoPorPersonaID)
		}
	}
}

// UpdateEstadoPorResidente es lo que alimenta ese filtro: si no dejara la
// persona anotada, el historial saldria vacio para todo el mundo.
func TestUpdateEstadoPorResidente_AnotaQuienResolvio(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	v := &Visita{
		TenantID: 1, Titular: "Ana", CasaDestino: "Casa 4", Estado: EstadoPendiente,
		KioskoID: 1, TipoVisitante: TipoVisitante("VISITANTE"),
		TipoDocumento: TipoDocumento("SIN_DOCUMENTO"),
	}
	if err := repo.Create(v); err != nil {
		t.Fatalf("no se pudo crear: %v", err)
	}

	ctx := context.WithValue(context.Background(), ctxkeys.TenantID, uint(1))
	if err := repo.WithContext(ctx).
		UpdateEstadoPorResidente(v.ID, EstadoRechazado, 10, "Ana Martinez"); err != nil {
		t.Fatalf("no se pudo actualizar: %v", err)
	}

	var guardada Visita
	if err := db.First(&guardada, v.ID).Error; err != nil {
		t.Fatalf("no se pudo releer: %v", err)
	}
	if guardada.Estado != EstadoRechazado {
		t.Errorf("esperaba RECHAZADO, got %s", guardada.Estado)
	}
	if guardada.AutorizadoPorTipo != AutorizadorResidente {
		t.Errorf("esperaba tipo RESIDENTE, got %s", guardada.AutorizadoPorTipo)
	}
	if guardada.AutorizadoPorPersonaID == nil || *guardada.AutorizadoPorPersonaID != 10 {
		t.Errorf("esperaba persona 10, got %v", guardada.AutorizadoPorPersonaID)
	}
	if guardada.AutorizadoPorNombre != "Ana Martinez" {
		t.Errorf("esperaba el nombre guardado, got %q", guardada.AutorizadoPorNombre)
	}
}

func TestFindHistorialResueltasPorPersona_Pagina(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	var yo uint = 10
	for i := 0; i < 5; i++ {
		quien := yo
		v := &Visita{
			TenantID: 1, Titular: "V", CasaDestino: "Casa 4", Estado: EstadoAprobado,
			AutorizadoPorTipo: AutorizadorResidente, AutorizadoPorPersonaID: &quien,
			KioskoID: 1, TipoVisitante: TipoVisitante("VISITANTE"),
			TipoDocumento: TipoDocumento("SIN_DOCUMENTO"),
		}
		if err := repo.Create(v); err != nil {
			t.Fatalf("no se pudo crear: %v", err)
		}
	}

	list, total, err := repo.FindHistorialResueltasPorPersona(1, yo, 2, 2)
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
