package destinos

import "gorm.io/gorm"

type Destino struct {
	gorm.Model
	TenantID uint   `gorm:"column:tenant_id;not null;index"`
	Nombre   string `gorm:"not null"`
	Titular  string `gorm:"not null"`
	KioskoID *uint  `gorm:"index"`
}

func (Destino) TableName() string { return "destinos" }
