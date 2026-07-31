package destinos

import "gorm.io/gorm"

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// Create crea un nuevo destino
func (r *Repository) Create(d *Destino) error {
	return r.db.Create(d).Error
}

// FindByKioskoID encuentra por destinos asociados a un kiosko por su kiosko_id
func (r *Repository) FindByKioskoID(kioskoID uint) ([]Destino, error) {
	var list []Destino
	if err := r.db.Where("kiosko_id = ?", kioskoID).
		Order("nombre ASC").
		Find(&list).
		Error; err != nil {
		return nil, err
	}
	return list, nil
}

// FindByNombreAndKioskoID busca el ID de un destino por nombre exacto y kiosko
func (r *Repository) FindByNombreAndKioskoID(nombre string, kioskoID uint) (uint, error) {
	var d Destino
	if err := r.db.Where("nombre = ? AND kiosko_id = ?", nombre, kioskoID).First(&d).Error; err != nil {
		return 0, err
	}
	return d.ID, nil
}

// VerificarOwnershipAdmin verifica que el kiosko pertenezca al admin antes de operar sobre sus destinos.
func (r *Repository) VerificarOwnershipAdmin(kioskoID, adminID uint) error {
	var count int64
	r.db.Table("kioskos").Where("id = ? AND admin_id = ?", kioskoID, adminID).Count(&count)
	if count == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// Delete elimina un destino por su id
func (r *Repository) Delete(id, kioskoID uint) error {
	result := r.db.Where("id = ? AND kiosko_id = ?", id, kioskoID).Delete(&Destino{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
