package persona

import (
	"time"

	"gorm.io/gorm"
)

// KigoVerifyEnrollment trackea un intento de verificación de identidad por
// liveness check con Kigo Verify (servicio HTTP externo). El backend nunca
// calcula el embedding facial — solo guarda el estado del enrollment y,
// cuando se completa, la foto ya alojada por nosotros (ver
// kigo_verify_handlers.go, webhook). El cálculo del embedding sigue siendo
// responsabilidad exclusiva de kigo-app, on-device.
type KigoVerifyEnrollment struct {
	gorm.Model
	PersonaID     uint   `gorm:"not null;index"`
	EnrollmentID  string `gorm:"not null;uniqueIndex"`
	WebhookSecret string `gorm:"not null"`
	Status        string    `gorm:"not null;default:'PENDING'"` // PENDING | COMPLETED | FAILED
	ExpiresAt     time.Time `gorm:"not null"`
	FotoRostroURL string    `gorm:"not null;default:''"`
}

type KigoVerifyRepository struct {
	db *gorm.DB
}

func NewKigoVerifyRepository(db *gorm.DB) *KigoVerifyRepository {
	return &KigoVerifyRepository{db: db}
}

func (r *KigoVerifyRepository) Crear(e *KigoVerifyEnrollment) error {
	return r.db.Create(e).Error
}

func (r *KigoVerifyRepository) FindByEnrollmentID(enrollmentID string) (*KigoVerifyEnrollment, error) {
	var e KigoVerifyEnrollment
	if err := r.db.Where("enrollment_id = ?", enrollmentID).First(&e).Error; err != nil {
		return nil, err
	}
	return &e, nil
}

// FindByPersonaAndEnrollmentID aísla la consulta por Persona — el endpoint
// de estado nunca debe dejar que una Persona consulte el enrollment de otra
// solo por adivinar su enrollment_id.
func (r *KigoVerifyRepository) FindByPersonaAndEnrollmentID(personaID uint, enrollmentID string) (*KigoVerifyEnrollment, error) {
	var e KigoVerifyEnrollment
	if err := r.db.Where("persona_id = ? AND enrollment_id = ?", personaID, enrollmentID).First(&e).Error; err != nil {
		return nil, err
	}
	return &e, nil
}

func (r *KigoVerifyRepository) ActualizarCompletado(id uint, fotoRostroURL string) error {
	return r.db.Model(&KigoVerifyEnrollment{}).Where("id = ?", id).
		Updates(map[string]any{"status": "COMPLETED", "foto_rostro_url": fotoRostroURL}).Error
}

// MarcarCompletado es un compare-and-set: solo escribe si el enrollment
// todavia no estaba COMPLETED. Devuelve la URL de la foto que quedo
// finalmente guardada -- la nuestra si ganamos la carrera, o la que ya
// estaba si el webhook y el polling llegaron a la vez. Sin esto, el que
// llegara segundo pisaba la foto del primero y la app podia recibir una
// URL distinta a la que se le habia respondido antes.
func (r *KigoVerifyRepository) MarcarCompletado(id uint, fotoRostroURL string) (string, error) {
	res := r.db.Model(&KigoVerifyEnrollment{}).
		Where("id = ? AND status <> ?", id, "COMPLETED").
		Updates(map[string]any{"status": "COMPLETED", "foto_rostro_url": fotoRostroURL})
	if res.Error != nil {
		return "", res.Error
	}
	if res.RowsAffected > 0 {
		return fotoRostroURL, nil
	}
	var e KigoVerifyEnrollment
	if err := r.db.First(&e, id).Error; err != nil {
		return "", err
	}
	return e.FotoRostroURL, nil
}

func (r *KigoVerifyRepository) ActualizarEstado(id uint, status string) error {
	return r.db.Model(&KigoVerifyEnrollment{}).Where("id = ?", id).Update("status", status).Error
}
