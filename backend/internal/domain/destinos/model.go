package destinos

import "gorm.io/gorm"

type Destino struct {
	gorm.Model
	Nombre   string `gorm:"not null"`
	Titular  string `gorm:"not null"`
	KioskoID uint   `gorm:"not null;index"`
}

func (Destino) TableName() string { return "destinos" }
