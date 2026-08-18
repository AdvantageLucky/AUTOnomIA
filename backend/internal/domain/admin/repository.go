/*
Package admin
Repositorio relacionado con modelo Admin

Operaciones CRUD en DB relacionadas solo con el dominio admin
*/
package admin

import (
	"gorm.io/gorm"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// Create crea un nuevo Admin
func (r *Repository) Create(a *Admin) error {
	return r.db.Create(a).Error
}

// FindByID encuentra un Admin por su id
func (r *Repository) FindByID(id uint) (*Admin, error) {
	var a Admin
	if err := r.db.First(&a, id).Error; err != nil {
		return nil, err
	}
	return &a, nil
}

// FindByCorreo encuentra un Admin por su correo, usado para validar login
func (r *Repository) FindByCorreo(correo string) (*Admin, error) {
	var a Admin
	if err := r.db.Where("correo = ?", correo).First(&a).Error; err != nil {
		return nil, err
	}
	return &a, nil
}

// Update actualiza la informacion de un Admin
func (r *Repository) Update(a *Admin) error {
	result := r.db.Where("id = ?", a.ID).Save(a)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// FindAllByTenant devuelve los admins del tenant dado; filtra por rol si se proporciona
func (r *Repository) FindAllByTenant(tenantID uint, rolFiltro string) ([]Admin, error) {
	var admins []Admin
	q := r.db.Model(&Admin{}).Where("tenant_id = ?", tenantID)
	if rolFiltro != "" {
		q = q.Where("rol = ?", rolFiltro)
	}
	return admins, q.Find(&admins).Error
}

// Delete elimina un Admin por su id
func (r *Repository) Delete(id uint) error {
	result := r.db.Delete(&Admin{}, id)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
