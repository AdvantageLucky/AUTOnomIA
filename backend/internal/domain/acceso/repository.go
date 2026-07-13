package acceso

import (
	"gorm.io/gorm"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// Create crea un nuevo Acceso
func (r *Repository) Create(a *Acceso) error {
	return r.db.Create(a).Error
}

// FindByID encuentra un Acceso por su id, sin filtrar por admin.
// Usado en el login del kiosko (auth/), que solo conoce su AccesoID y su ClaveKiosko, no un adminID.
func (r *Repository) FindByID(id uint) (*Acceso, error) {
	var a Acceso
	if err := r.db.First(&a, id).Error; err != nil {
		return nil, err
	}
	return &a, nil
}

// FindByIDAndAdminID encuentra un Acceso usando su id y el admin_id al que pertenece
func (r *Repository) FindByIDAndAdminID(accesoID, adminID uint) (*Acceso, error) {
	var a Acceso
	if err := r.db.Where("id = ? AND admin_id = ?", accesoID, adminID).
		First(&a).
		Error; err != nil {
		return nil, err
	}
	return &a, nil
}

// FindAllByAdminID encuentra todos los Accesos de un Admin usando acceso_id y admin_id
func (r *Repository) FindAllByAdminID(adminID uint) ([]Acceso, error) {
	var accesos []Acceso

	if err := r.db.Where("admin_id = ?", adminID).Find(&accesos).Error; err != nil {
		return nil, err
	}
	return accesos, nil
}

// Update actualiza la informacion de un Acceso usando admin_id
func (r *Repository) Update(a *Acceso, adminID uint) error {
	result := r.db.Where("admin_id = ?", adminID).Save(a)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// Delete elimina un Acceso usando acceso_id y admin_id
func (r *Repository) Delete(id uint, adminID uint) error {
	result := r.db.Where("admin_id = ?", adminID).Delete(&Acceso{}, id)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
