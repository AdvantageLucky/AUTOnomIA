package visitas

import (
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
