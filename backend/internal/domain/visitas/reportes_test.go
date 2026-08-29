package visitas

import (
	"strings"
	"testing"
	"time"
)

func TestReporteRepository_Paginados(t *testing.T) {
	db := setupTestDB(t)
	if err := db.AutoMigrate(&ReporteIA{}); err != nil {
		t.Fatalf("no se pudo migrar ReporteIA: %v", err)
	}
	repo := &reporteRepository{db: db}

	base := time.Now().Add(-72 * time.Hour)
	for i := 0; i < 5; i++ {
		r := &ReporteIA{
			TenantID:      1,
			PeriodoInicio: base.Add(time.Duration(i) * time.Hour),
			PeriodoFin:    base.Add(time.Duration(i+1) * time.Hour),
			Texto:         "reporte de prueba",
		}
		if err := repo.guardar(r); err != nil {
			t.Fatalf("no se pudo crear el reporte %d: %v", i, err)
		}
		db.Model(r).UpdateColumn("created_at", base.Add(time.Duration(i)*time.Hour))
	}

	list, total, err := repo.paginados(1, 2)
	if err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}
	if total != 5 {
		t.Errorf("esperaba total=5, got %d", total)
	}
	if len(list) != 2 {
		t.Fatalf("esperaba 2 resultados en la primera pagina, got %d", len(list))
	}
	// El mas reciente (i=4) debe venir primero.
	if list[0].Texto != "reporte de prueba" {
		t.Errorf("esperaba texto de prueba, got %q", list[0].Texto)
	}

	list2, _, err := repo.paginados(2, 2)
	if err != nil {
		t.Fatalf("no esperaba error en la segunda pagina: %v", err)
	}
	if len(list2) != 2 {
		t.Fatalf("esperaba 2 resultados en la segunda pagina, got %d", len(list2))
	}
}

// TestGenerarReporte_LLMFalla_UsaResumirDatosTexto fija el comportamiento
// que arregla el bug reportado: antes, GenerarResumen nunca devolvía error
// (siempre nil), así que esta rama nunca se ejecutaba y el reporte se
// quedaba con el heurístico genérico por-visita en vez del agregado real
// del período (visitas/aprobadas/rechazadas/en revisión).
func TestGenerarReporte_LLMFalla_UsaResumirDatosTexto(t *testing.T) {
	db := setupTestDB(t)
	if err := db.AutoMigrate(&ReporteIA{}); err != nil {
		t.Fatalf("no se pudo migrar ReporteIA: %v", err)
	}
	repo := &reporteRepository{db: db}
	visitaRepo := NewRepository(db)

	const tenantID = uint(1)
	db.Create(&Visita{
		TenantID: tenantID, Titular: "Ana", Curp: "X", FotoDocumentoURL: "x", FotoRostroURL: "x",
		CasaDestino: "CASA 1", Estado: EstadoAprobado, KioskoID: 1,
	})
	db.Create(&Visita{
		TenantID: tenantID, Titular: "Beto", Curp: "X", FotoDocumentoURL: "x", FotoRostroURL: "x",
		CasaDestino: "CASA 1", Estado: EstadoRechazado, KioskoID: 1,
	})

	// Puerto que nadie escucha: la llamada al LLM falla de verdad.
	generarReporte(repo, visitaRepo, "http://localhost:1", tenantID)

	var reportes []ReporteIA
	if err := db.Where("tenant_id = ?", tenantID).Find(&reportes).Error; err != nil {
		t.Fatalf("no se pudo leer el reporte: %v", err)
	}
	if len(reportes) != 1 {
		t.Fatalf("esperaba 1 reporte, got %d", len(reportes))
	}
	if !strings.Contains(reportes[0].Texto, "Período de 12h") {
		t.Errorf("esperaba el texto de resumirDatosTexto (agregado del período), got %q", reportes[0].Texto)
	}
	if !strings.Contains(reportes[0].Texto, "2 visitas totales") {
		t.Errorf("esperaba el conteo real de visitas en el texto, got %q", reportes[0].Texto)
	}
}
