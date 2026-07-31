package invitaciones

import (
	"errors"
	"time"

	"gorm.io/gorm"
)

var ErrInvitacionNoValida = errors.New("invitacion no valida, expirada o agotada")

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) Create(inv *Invitacion) error {
	return r.db.Create(inv).Error
}

func (r *Repository) FindByResidenteID(residenteID uint) ([]Invitacion, error) {
	var list []Invitacion
	err := r.db.Where("residente_id = ?", residenteID).
		Order("created_at DESC").
		Find(&list).Error
	return list, err
}

// FindByToken busca una invitacion activa por su token
// Devuelve ErrInvitacionNoValida si está revocada, expirada o agotada.
func (r *Repository) FindByToken(token string) (*Invitacion, error) {
	var inv Invitacion
	if err := r.db.Where("token = ?", token).First(&inv).Error; err != nil {
		return nil, ErrInvitacionNoValida
	}
	if inv.ExpiresAt != nil && inv.ExpiresAt.Before(time.Now()) {
		return nil, ErrInvitacionNoValida
	}
	if inv.MaxUsos != nil && inv.ConteoUsos >= *inv.MaxUsos {
		return nil, ErrInvitacionNoValida
	}
	return &inv, nil
}

// RevocarByID hace soft-delete comprobando que la invitación pertenece al residente
func (r *Repository) RevocarByID(id, residenteID uint) error {
	result := r.db.Where("id = ? AND residente_id = ?", id, residenteID).Delete(&Invitacion{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// IncrementarUso suma uno al ConteoUsos y si el resultado alcanza MaxUsos entonces revoca
func (r *Repository) IncrementarUso(id uint) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		var inv Invitacion
		if err := tx.First(&inv, id).Error; err != nil {
			return err
		}
		inv.ConteoUsos++
		if err := tx.Save(&inv).Error; err != nil {
			return err
		}
		if inv.MaxUsos != nil && inv.ConteoUsos >= *inv.MaxUsos {
			return tx.Delete(&inv).Error
		}
		return nil
	})
}
