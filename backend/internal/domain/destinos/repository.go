package destinos

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

// WithContext retorna una instancia del repositorio vinculada al contexto HTTP
func (r *Repository) WithContext(ctx context.Context) *Repository {
	return &Repository{db: r.db.WithContext(ctx)}
}

// ByTenant aisla las consultas usando el tenant_id inyectado en el contexto
func ByTenant(db *gorm.DB) *gorm.DB {
	if tenantID, ok := db.Statement.Context.Value(ctxkeys.TenantID).(uint); ok && tenantID > 0 {
		return db.Where("tenant_id = ?", tenantID)
	}
	return db
}

func (r *Repository) Create(d *Destino) error {
	return r.db.Create(d).Error
}

func (r *Repository) FindByKioskoID(kioskoID uint) ([]Destino, error) {
	var list []Destino
	if err := r.db.Scopes(ByTenant).Where("kiosko_id = ?", kioskoID).
		Order("nombre ASC").
		Find(&list).
		Error; err != nil {
		return nil, err
	}
	return list, nil
}

func (r *Repository) FindByNombreAndKioskoID(nombre string, kioskoID uint) (uint, error) {
	var d Destino
	if err := r.db.Scopes(ByTenant).Where("nombre = ? AND kiosko_id = ?", nombre, kioskoID).First(&d).Error; err != nil {
		return 0, err
	}
	return d.ID, nil
}

func (r *Repository) VerificarOwnershipAdmin(kioskoID, adminID uint) error {
	var count int64
	r.db.Scopes(ByTenant).Table("kioskos").Where("id = ? AND admin_id = ?", kioskoID, adminID).Count(&count)
	if count == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (r *Repository) Delete(id, kioskoID uint) error {
	result := r.db.Scopes(ByTenant).Where("id = ? AND kiosko_id = ?", id, kioskoID).Delete(&Destino{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
