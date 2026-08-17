package persona

import (
	"time"

	"gorm.io/gorm"
)

type OtpRepository struct {
	db *gorm.DB
}

func NewOtpRepository(db *gorm.DB) *OtpRepository {
	return &OtpRepository{db: db}
}

func (r *OtpRepository) Create(o *OtpSolicitud) error {
	return r.db.Create(o).Error
}

// FindActivaPorTelefono busca la solicitud de OTP más reciente para un
// teléfono que todavía no haya vencido.
func (r *OtpRepository) FindActivaPorTelefono(telefono string) (*OtpSolicitud, error) {
	var o OtpSolicitud
	if err := r.db.
		Where("telefono = ? AND expira_en > ?", telefono, time.Now()).
		Order("created_at DESC").
		First(&o).Error; err != nil {
		return nil, err
	}
	return &o, nil
}

// InvalidarPorTelefono borra (soft-delete) todas las solicitudes de un
// teléfono — se llama tras una verificación exitosa, para que el mismo
// código no se pueda reusar.
func (r *OtpRepository) InvalidarPorTelefono(telefono string) error {
	return r.db.Where("telefono = ?", telefono).Delete(&OtpSolicitud{}).Error
}
