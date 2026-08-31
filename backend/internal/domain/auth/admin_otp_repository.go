package auth

import (
	"time"

	"gorm.io/gorm"
)

type AdminOtpRepository struct {
	db *gorm.DB
}

func NewAdminOtpRepository(db *gorm.DB) *AdminOtpRepository {
	return &AdminOtpRepository{db: db}
}

func (r *AdminOtpRepository) Create(o *AdminOtpSolicitud) error {
	return r.db.Create(o).Error
}

// FindActivaPorCorreo busca la solicitud de OTP más reciente para un correo
// que todavía no haya vencido.
func (r *AdminOtpRepository) FindActivaPorCorreo(correo string) (*AdminOtpSolicitud, error) {
	var o AdminOtpSolicitud
	if err := r.db.
		Where("correo = ? AND expira_en > ?", correo, time.Now()).
		Order("created_at DESC").
		First(&o).Error; err != nil {
		return nil, err
	}
	return &o, nil
}

// InvalidarPorCorreo borra (soft-delete) todas las solicitudes de un correo
// -- se llama tras una verificación exitosa, para que el mismo código no se
// pueda reusar.
func (r *AdminOtpRepository) InvalidarPorCorreo(correo string) error {
	return r.db.Where("correo = ?", correo).Delete(&AdminOtpSolicitud{}).Error
}

// IncrementarIntentos suma uno a los intentos fallidos de una solicitud de
// OTP y devuelve el nuevo total -- usado para cortar por fuerza bruta.
func (r *AdminOtpRepository) IncrementarIntentos(id uint) (int, error) {
	if err := r.db.Model(&AdminOtpSolicitud{}).Where("id = ?", id).
		Update("intentos", gorm.Expr("intentos + 1")).Error; err != nil {
		return 0, err
	}
	var o AdminOtpSolicitud
	if err := r.db.Select("intentos").First(&o, id).Error; err != nil {
		return 0, err
	}
	return o.Intentos, nil
}
