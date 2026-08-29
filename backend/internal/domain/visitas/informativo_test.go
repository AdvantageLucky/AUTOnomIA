package visitas

import (
	"encoding/json"
	"testing"
	"time"

	"kigo-autonomia-backend/internal/domain/kiosko"
)

func TestAnalizarYGuardarInformativo_NuncaCambiaElEstado(t *testing.T) {
	db := setupTestDB(t)
	if err := db.AutoMigrate(&kiosko.KioskoConfig{}); err != nil {
		t.Fatalf("no se pudo migrar KioskoConfig: %v", err)
	}
	repo := NewRepository(db)

	const tenantID = uint(1)
	// Historial con una anomalía clara (matrícula distinta) para forzar
	// que, si el código tocara el estado, lo mandaría a REVISION.
	db.Create(&Visita{
		TenantID: tenantID, Titular: "Ana", Curp: "X", FotoDocumentoURL: "x", FotoRostroURL: "x",
		CasaDestino: "CASA 1", Placa: "AAA111", Estado: EstadoAprobado, KioskoID: 1,
	})
	v := &Visita{
		TenantID: tenantID, Titular: "Ana", Curp: "X", FotoDocumentoURL: "x", FotoRostroURL: "x",
		CasaDestino: "CASA 1", Placa: "BBB222", Estado: EstadoAprobado, KioskoID: 1,
	}
	if err := repo.Create(v); err != nil {
		t.Fatalf("no se pudo crear la visita: %v", err)
	}

	AnalizarYGuardarInformativo(repo, tenantID, *v, "")

	var actualizada Visita
	if err := db.First(&actualizada, v.ID).Error; err != nil {
		t.Fatalf("no se pudo leer la visita: %v", err)
	}
	if actualizada.Estado != EstadoAprobado {
		t.Errorf("esperaba que el Estado siguiera APROBADO, got %q", actualizada.Estado)
	}
}

func TestAnalizarYGuardarInformativo_GuardaResumenYScore(t *testing.T) {
	db := setupTestDB(t)
	if err := db.AutoMigrate(&kiosko.KioskoConfig{}); err != nil {
		t.Fatalf("no se pudo migrar KioskoConfig: %v", err)
	}
	repo := NewRepository(db)

	const tenantID = uint(1)
	v := &Visita{
		TenantID: tenantID, Titular: "Ana", Curp: "X", FotoDocumentoURL: "x", FotoRostroURL: "x",
		CasaDestino: "CASA 1", Estado: EstadoAprobado, KioskoID: 1,
	}
	if err := repo.Create(v); err != nil {
		t.Fatalf("no se pudo crear la visita: %v", err)
	}

	AnalizarYGuardarInformativo(repo, tenantID, *v, "")

	var actualizada Visita
	if err := db.First(&actualizada, v.ID).Error; err != nil {
		t.Fatalf("no se pudo leer la visita: %v", err)
	}
	if actualizada.ResumenIA == "" {
		t.Error("esperaba resumen_ia no vacío")
	}
	var sc ScoreIA
	if err := json.Unmarshal(actualizada.ScoreIA, &sc); err != nil {
		t.Fatalf("score_ia no es JSON válido: %v", err)
	}
}

func TestAnalizarYGuardarInformativo_IntervenidaSegunAnomalia_NoSegunEstado(t *testing.T) {
	db := setupTestDB(t)
	if err := db.AutoMigrate(&kiosko.KioskoConfig{}); err != nil {
		t.Fatalf("no se pudo migrar KioskoConfig: %v", err)
	}
	repo := NewRepository(db)

	const tenantID = uint(1)
	// Placa distinta a la visita previa -> AnomaliaMatricula -> tieneAnomalias=true,
	// pese a que el Estado se queda APROBADO (nunca cambia en este flujo).
	previa := &Visita{
		TenantID: tenantID, Titular: "Ana", Curp: "X", FotoDocumentoURL: "x", FotoRostroURL: "x",
		CasaDestino: "CASA 1", Placa: "AAA111", Estado: EstadoAprobado, KioskoID: 1,
	}
	if err := repo.Create(previa); err != nil {
		t.Fatalf("no se pudo crear la visita previa: %v", err)
	}
	db.Model(previa).UpdateColumn("created_at", time.Now().Add(-2*time.Hour))

	v := &Visita{
		TenantID: tenantID, Titular: "Ana", Curp: "X", FotoDocumentoURL: "x", FotoRostroURL: "x",
		CasaDestino: "CASA 1", Placa: "BBB222", Estado: EstadoAprobado, KioskoID: 1,
	}
	if err := repo.Create(v); err != nil {
		t.Fatalf("no se pudo crear la visita: %v", err)
	}

	AnalizarYGuardarInformativo(repo, tenantID, *v, "")

	var actualizada Visita
	if err := db.First(&actualizada, v.ID).Error; err != nil {
		t.Fatalf("no se pudo leer la visita: %v", err)
	}
	if !actualizada.Intervenida {
		t.Error("esperaba Intervenida=true por la anomalía de matrícula, pese a que el Estado no cambió")
	}
	if actualizada.Estado != EstadoAprobado {
		t.Errorf("esperaba Estado sin cambios (APROBADO), got %q", actualizada.Estado)
	}
}
