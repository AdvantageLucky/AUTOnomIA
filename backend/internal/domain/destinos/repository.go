package destinos

import (
	"context"
	"errors"

	"gorm.io/gorm"
)

var ErrTenantNoResuelto = errors.New("tenant_id no resuelto en el contexto")

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) WithContext(ctx context.Context) *Repository {
	return &Repository{db: r.db.WithContext(ctx)}
}

func (r *Repository) Create(d *Destino) error {
	return r.db.Create(d).Error
}

// CreateLote inserta varios destinos en una sola transacción — alta masiva
// desde el dashboard en vez de un POST por cada uno.
func (r *Repository) CreateLote(destinos []Destino) error {
	if len(destinos) == 0 {
		return nil
	}
	return r.db.Create(&destinos).Error
}

func (r *Repository) FindByTenantID(tenantID uint) ([]Destino, error) {
	if tenantID == 0 {
		return nil, ErrTenantNoResuelto
	}
	var list []Destino
	if err := r.db.Where("tenant_id = ?", tenantID).Order("nombre ASC").Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}

// ListNombresByTenantID devuelve solo los nombres de los destinos del tenant,
// usado por el registro público de residentes para ofrecer un selector de casas.
func (r *Repository) ListNombresByTenantID(tenantID uint) ([]string, error) {
	if tenantID == 0 {
		return nil, ErrTenantNoResuelto
	}
	var nombres []string
	if err := r.db.Model(&Destino{}).
		Where("tenant_id = ?", tenantID).
		Order("nombre ASC").
		Pluck("nombre", &nombres).Error; err != nil {
		return nil, err
	}
	return nombres, nil
}

func (r *Repository) FindByNombreAndTenantID(nombre string, tenantID uint) (uint, error) {
	if tenantID == 0 {
		return 0, ErrTenantNoResuelto
	}
	var d Destino
	if err := r.db.Where("nombre = ? AND tenant_id = ?", nombre, tenantID).First(&d).Error; err != nil {
		return 0, err
	}
	return d.ID, nil
}

func (r *Repository) FindByID(id uint) (*Destino, error) {
	var d Destino
	if err := r.db.First(&d, id).Error; err != nil {
		return nil, err
	}
	return &d, nil
}

func (r *Repository) Delete(id, tenantID uint) error {
	if tenantID == 0 {
		return ErrTenantNoResuelto
	}
	result := r.db.Where("id = ? AND tenant_id = ?", id, tenantID).Delete(&Destino{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
