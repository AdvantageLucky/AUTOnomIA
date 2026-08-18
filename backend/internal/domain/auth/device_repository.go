package auth

import (
	"time"

	"gorm.io/gorm"
)

type DeviceRepository struct {
	db *gorm.DB
}

func NewDeviceRepository(db *gorm.DB) *DeviceRepository {
	return &DeviceRepository{db: db}
}

func (r *DeviceRepository) Create(da *DeviceAuthorization) error {
	return r.db.Create(da).Error
}

// FindByDeviceCode busca una autorización activa (no expirada, no soft-deleted) por device_code.
func (r *DeviceRepository) FindByDeviceCode(code string) (*DeviceAuthorization, error) {
	var da DeviceAuthorization
	err := r.db.Where("device_code = ? AND deleted_at IS NULL", code).First(&da).Error
	if err != nil {
		return nil, err
	}
	if time.Now().After(da.ExpiresAt) && da.Status == DeviceStatusPending {
		return &da, nil // devuelve con status pending pero expirado — el handler decide
	}
	return &da, nil
}

// FindByUserCode busca una autorización pendiente por user_code para que el admin la apruebe.
func (r *DeviceRepository) FindByUserCode(code string) (*DeviceAuthorization, error) {
	var da DeviceAuthorization
	err := r.db.Where("user_code = ? AND status = ? AND deleted_at IS NULL", code, DeviceStatusPending).
		First(&da).Error
	if err != nil {
		return nil, err
	}
	return &da, nil
}

// FindPendingByTenant lista autorizaciones pendientes y no expiradas para un tenant.
func (r *DeviceRepository) FindPendingByTenant(tenantID uint) ([]DeviceAuthorization, error) {
	var list []DeviceAuthorization
	err := r.db.Where(
		"tenant_id = ? AND status = ? AND expires_at > ? AND deleted_at IS NULL",
		tenantID, DeviceStatusPending, time.Now(),
	).Order("created_at ASC").Find(&list).Error
	return list, err
}

// Aprobar marca la autorización como aprobada, asigna kiosko/tenant y guarda la clave en claro
// para que el dispositivo la recupere al canjear el token.
func (r *DeviceRepository) Aprobar(userCode string, kioskoID, tenantID uint, claveKiosko string) error {
	return r.db.Model(&DeviceAuthorization{}).
		Where("user_code = ? AND status = ? AND deleted_at IS NULL", userCode, DeviceStatusPending).
		Updates(map[string]any{
			"status":             DeviceStatusApproved,
			"kiosko_id":          kioskoID,
			"tenant_id":          tenantID,
			"clave_kiosko_plain": claveKiosko,
		}).Error
}

// LimpiarClave borra la clave en claro una vez que el dispositivo ya la recibió.
func (r *DeviceRepository) LimpiarClave(id uint) error {
	return r.db.Model(&DeviceAuthorization{}).Where("id = ?", id).
		Update("clave_kiosko_plain", nil).Error
}

// SoftDelete marca la autorización como eliminada (después de que el dispositivo ya obtuvo su token).
func (r *DeviceRepository) SoftDelete(id uint) error {
	now := time.Now()
	return r.db.Model(&DeviceAuthorization{}).Where("id = ?", id).Update("deleted_at", now).Error
}
