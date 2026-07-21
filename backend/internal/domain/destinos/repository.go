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

// FindByAccesoID encuentra por destinos asociados a un kiosko por su kiosko_id
func (r *Repository) FindByAccesoID(accesoID uint) ([]Destino, error) {
	var list []Destino
	if err := r.db.Where("acceso_id = ?", accesoID).
		Order("nombre ASC").
		Find(&list).
		Error; err != nil {
		return nil, err
	}
	return list, nil
}

// Delete elimina un destino por su id
func (r *Repository) Delete(id, accesoID uint) error {
	result := r.db.Where("id = ? AND acceso_id = ?", id, accesoID).Delete(&Destino{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
