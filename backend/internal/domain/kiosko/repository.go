/*
Package kiosko
Repositorio relacionado con la tabla kioskos

Funciones CRUD relacionadas solo con el dominio Kiosko, es decir operaciones CRUD
en tabla kioskos y kiosko_configs
*/
package kiosko

import (
	"context"

	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"gorm.io/gorm"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// WithContext retorna una instancia del repositorio vinculada al contexto HTTP de la petición
func (r *Repository) WithContext(ctx context.Context) *Repository {
	return &Repository{db: r.db.WithContext(ctx)}
}

// ByTenant es un GORM Scope que aísla las consultas usando el tenant_id del contexto.
// Califica la columna con el nombre de tabla cuando está disponible para evitar
// ambigüedad en consultas con JOIN contra otras tablas que también tienen tenant_id.
func ByTenant(db *gorm.DB) *gorm.DB {
	if tenantID, ok := db.Statement.Context.Value(ctxkeys.TenantID).(uint); ok && tenantID > 0 {
		if table := db.Statement.Table; table != "" {
			return db.Where(table+".tenant_id = ?", tenantID)
		}
		return db.Where("tenant_id = ?", tenantID)
	}
	return db
}

// Create crea un nuevo Kiosko
func (r *Repository) Create(a *Kiosko) error {
	return r.db.Create(a).Error
}

// FindByID encuentra un Kiosko por su id asegurando pertenecer al tenant activo
func (r *Repository) FindByID(id uint) (*Kiosko, error) {
	var a Kiosko
	if err := r.db.Scopes(ByTenant).First(&a, id).Error; err != nil {
		return nil, err
	}
	return &a, nil
}

// FindByIDAndAdminID encuentra un Kiosko usando su id, admin_id y el tenant activo
func (r *Repository) FindByIDAndAdminID(kioskoID, adminID uint) (*Kiosko, error) {
	var a Kiosko
	if err := r.db.Scopes(ByTenant).Where("id = ? AND admin_id = ?", kioskoID, adminID).
		First(&a).
		Error; err != nil {
		return nil, err
	}
	return &a, nil
}

// FindAllByAdminID encuentra todos los Kioskos de un Admin filtrados por el tenant activo
func (r *Repository) FindAllByAdminID(adminID uint) ([]Kiosko, error) {
	var kioskos []Kiosko

	if err := r.db.Scopes(ByTenant).Where("admin_id = ?", adminID).Find(&kioskos).Error; err != nil {
		return nil, err
	}
	return kioskos, nil
}

// Update actualiza la informacion de un Kiosko usando admin_id y el tenant activo
func (r *Repository) Update(a *Kiosko, adminID uint) error {
	result := r.db.Scopes(ByTenant).Where("admin_id = ?", adminID).Save(a)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// FindConfigByKioskoID devuelve la KioskoConfig del kiosko validando tenant; la crea con defaults si no existe
func (r *Repository) FindConfigByKioskoID(kioskoID uint) (*KioskoConfig, error) {
	var cfg KioskoConfig
	if _, err := r.FindByID(kioskoID); err != nil {
		return nil, err
	}

	err := r.db.Where("kiosko_id = ?", kioskoID).First(&cfg).Error
	if err == gorm.ErrRecordNotFound {
		cfg = KioskoConfig{KioskoID: kioskoID}
		if err = r.db.Create(&cfg).Error; err != nil {
			return nil, err
		}
		return &cfg, nil
	}
	return &cfg, err
}

// UpdateConfig guarda los campos de KioskoConfig para el kiosko indicado
func (r *Repository) UpdateConfig(cfg *KioskoConfig) error {
	if _, err := r.FindByID(cfg.KioskoID); err != nil {
		return err
	}
	return r.db.Save(cfg).Error
}

// Delete elimina un Kiosko usando kiosko_id, admin_id y el tenant activo
func (r *Repository) Delete(id uint, adminID uint) error {
	result := r.db.Scopes(ByTenant).Where("admin_id = ?", adminID).Delete(&Kiosko{}, id)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
