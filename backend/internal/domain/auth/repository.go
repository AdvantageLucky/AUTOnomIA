/*
Package auth
Repositorio relacionado con la tabla de sesiones de Kiosko

Funciones CRUD relacionadas solo con el dominio auth para las sesiones persistidas
*/
package auth

import "gorm.io/gorm"

type SesionRepository struct {
	db *gorm.DB
}

func NewSesionRepository(db *gorm.DB) *SesionRepository {
	return &SesionRepository{db: db}
}

// Create persiste una nueva sesion de kiosko
func (r *SesionRepository) Create(s *SesionKiosko) error {
	return r.db.Create(s).Error
}

// FindActiveByToken encuentra una sesion por su token, solo si no ha sido revocada
func (r *SesionRepository) FindActiveByToken(token string) (*SesionKiosko, error) {
	var s SesionKiosko
	if err := r.db.Where("token = ? AND revocada = ?", token, false).First(&s).Error; err != nil {
		return nil, err
	}
	return &s, nil
}

// RevokeAllByKioskoID revoca todas las sesiones activas de un Kiosko (ej. kiosko robado/perdido)
func (r *SesionRepository) RevokeAllByKioskoID(kioskoID uint) error {
	return r.db.Model(&SesionKiosko{}).
		Where("kiosko_id = ? AND revocada = ?", kioskoID, false).
		Update("revocada", true).
		Error
}
