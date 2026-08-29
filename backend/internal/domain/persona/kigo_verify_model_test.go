package persona

import (
	"testing"
	"time"
)

func TestKigoVerifyRepository_CrearYBuscar(t *testing.T) {
	db := setupTestDB(t)
	if err := db.AutoMigrate(&KigoVerifyEnrollment{}); err != nil {
		t.Fatalf("no se pudo migrar KigoVerifyEnrollment: %v", err)
	}
	repo := NewKigoVerifyRepository(db)

	e := &KigoVerifyEnrollment{
		PersonaID:     1,
		EnrollmentID:  "enr-abc",
		WebhookSecret: "secreto",
		Status:        "PENDING",
		ExpiresAt:     time.Now().Add(24 * time.Hour),
	}
	if err := repo.Crear(e); err != nil {
		t.Fatalf("no se pudo crear: %v", err)
	}

	encontrado, err := repo.FindByEnrollmentID("enr-abc")
	if err != nil {
		t.Fatalf("no se pudo buscar por enrollment_id: %v", err)
	}
	if encontrado.PersonaID != 1 || encontrado.Status != "PENDING" {
		t.Errorf("datos inesperados: %+v", encontrado)
	}

	porPersona, err := repo.FindByPersonaAndEnrollmentID(1, "enr-abc")
	if err != nil {
		t.Fatalf("no se pudo buscar por persona+enrollment_id: %v", err)
	}
	if porPersona.ID != encontrado.ID {
		t.Errorf("esperaba el mismo registro")
	}

	_, err = repo.FindByPersonaAndEnrollmentID(999, "enr-abc")
	if err == nil {
		t.Error("esperaba error al buscar con una persona distinta")
	}
}

func TestKigoVerifyRepository_ActualizarCompletado(t *testing.T) {
	db := setupTestDB(t)
	if err := db.AutoMigrate(&KigoVerifyEnrollment{}); err != nil {
		t.Fatalf("no se pudo migrar KigoVerifyEnrollment: %v", err)
	}
	repo := NewKigoVerifyRepository(db)

	e := &KigoVerifyEnrollment{
		PersonaID: 1, EnrollmentID: "enr-xyz", WebhookSecret: "s",
		Status: "PENDING", ExpiresAt: time.Now().Add(24 * time.Hour),
	}
	repo.Crear(e)

	if err := repo.ActualizarCompletado(e.ID, "https://x/foto.jpg"); err != nil {
		t.Fatalf("no se pudo actualizar: %v", err)
	}

	actualizado, _ := repo.FindByEnrollmentID("enr-xyz")
	if actualizado.Status != "COMPLETED" || actualizado.FotoRostroURL != "https://x/foto.jpg" {
		t.Errorf("esperaba COMPLETED con la foto, got %+v", actualizado)
	}
}
