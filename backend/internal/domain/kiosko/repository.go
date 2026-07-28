/*
Package kiosko
Repositorio relacionado con la tabla kioskos

Funciones CRUD relacionadas solo con el dominio Kiosko, es decir operaciones CRUD
en tabla kioskos y kiosko_configs
*/
package kiosko

import "gorm.io/gorm"

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// Create crea un nuevo Kiosko
func (r *Repository) Create(a *Kiosko) error {
	return r.db.Create(a).Error
}

// FindByID encuentra un Kiosko por su id
// Usado en el login del kiosko (auth/), que solo conoce su KioskoID y su ClaveKiosko, no un adminID
func (r *Repository) FindByID(id uint) (*Kiosko, error) {
	var a Kiosko
	if err := r.db.First(&a, id).Error; err != nil {
		return nil, err
	}
	return &a, nil
}

// FindByIDAndAdminID encuentra un Kiosko usando su id y el admin_id al que pertenece
func (r *Repository) FindByIDAndAdminID(kioskoID, adminID uint) (*Kiosko, error) {
	var a Kiosko
	if err := r.db.Where("id = ? AND admin_id = ?", kioskoID, adminID).
		First(&a).
		Error; err != nil {
		return nil, err
	}
	return &a, nil
}

// FindAllByAdminID encuentra todos los Kioskos de un Admin usando kiosko_id y admin_id
func (r *Repository) FindAllByAdminID(adminID uint) ([]Kiosko, error) {
	var kioskos []Kiosko

	if err := r.db.Where("admin_id = ?", adminID).Find(&kioskos).Error; err != nil {
		return nil, err
	}
	return kioskos, nil
}

// Update actualiza la informacion de un Kiosko usando admin_id
func (r *Repository) Update(a *Kiosko, adminID uint) error {
	result := r.db.Where("admin_id = ?", adminID).Save(a)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// FindConfigByKioskoID devuelve la KioskoConfig del kiosko; la crea con defaults si no existe
func (r *Repository) FindConfigByKioskoID(kioskoID uint) (*KioskoConfig, error) {
	var cfg KioskoConfig
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
// Solo admins que posean el kiosko deben poder llamar esto (validado en el handler)
func (r *Repository) UpdateConfig(cfg *KioskoConfig) error {
	return r.db.Save(cfg).Error
}

// Delete elimina un Kiosko usando kiosko_id y admin_id
func (r *Repository) Delete(id uint, adminID uint) error {
	result := r.db.Where("admin_id = ?", adminID).Delete(&Kiosko{}, id)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
