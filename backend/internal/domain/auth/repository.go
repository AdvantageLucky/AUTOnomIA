package auth

import "gorm.io/gorm"

type SesionRepository struct {
	db *gorm.DB
}

func NewSesionRepository(db *gorm.DB) *SesionRepository {
	return &SesionRepository{db: db}
}

// Create persiste una nueva sesion de kiosko
func (r *SesionRepository) Create(s *SesionAcceso) error {
	return r.db.Create(s).Error
}

// FindActiveByToken encuentra una sesion por su token, solo si no ha sido revocada
func (r *SesionRepository) FindActiveByToken(token string) (*SesionAcceso, error) {
	var s SesionAcceso
	if err := r.db.Where("token = ? AND revocada = ?", token, false).First(&s).Error; err != nil {
		return nil, err
	}
	return &s, nil
}

// RevokeAllByAccesoID revoca todas las sesiones activas de un Acceso (ej. kiosko robado/perdido)
func (r *SesionRepository) RevokeAllByAccesoID(accesoID uint) error {
	return r.db.Model(&SesionAcceso{}).
		Where("acceso_id = ? AND revocada = ?", accesoID, false).
		Update("revocada", true).
		Error
}
