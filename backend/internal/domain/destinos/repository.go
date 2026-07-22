/*
Package destinos
Repositorio relacionado con la tabla destinos

Funciones CRUD relacionadas solo con el dominio destinos, es decir operaciones CRUD en tabla destinos
*/
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
