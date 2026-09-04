// Package salidas registra la bitácora del kiosko de salida -- un segundo
// dispositivo, aparte del kiosko de entrada, con un flujo deliberadamente
// mínimo (tap + foto de rostro, sin OCR ni QR): no hay identidad contra la
// que resolver, así que esto es solo un registro de "alguien salió aquí, a
// esta hora, con esta foto", no una decisión de acceso.
package salidas

import "gorm.io/gorm"

type Salida struct {
	gorm.Model
	TenantID uint   `gorm:"column:tenant_id;not null;index"`
	KioskoID uint   `gorm:"column:kiosko_id;not null;index"`
	FotoURL  string `gorm:"column:foto_url;not null;default:''"`
}

func (Salida) TableName() string { return "salidas" }

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) Crear(s *Salida) error {
	return r.db.Create(s).Error
}

// SalidaConNombre es el destino del join en ListarPorTenant -- mismo patron
// que EventoConNombre en seguridad/model.go.
type SalidaConNombre struct {
	Salida
	KioskoNombre string
}

// ListarPorTenant trae las salidas de un tenant, con el nombre del kiosko
// resuelto via join, mas recientes primero -- limitado a 200 por el mismo
// motivo que seguridad.Repository.ListarPorTenant.
func (r *Repository) ListarPorTenant(tenantID uint) ([]SalidaConNombre, error) {
	var list []SalidaConNombre
	err := r.db.Table("salidas").
		Select("salidas.*, kioskos.nombre AS kiosko_nombre").
		Joins("JOIN kioskos ON kioskos.id = salidas.kiosko_id").
		Where("salidas.tenant_id = ?", tenantID).
		Where("salidas.deleted_at IS NULL").
		Order("salidas.created_at DESC").
		Limit(200).
		Scan(&list).Error
	return list, err
}
