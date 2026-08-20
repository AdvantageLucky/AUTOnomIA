package destinos

import "gorm.io/gorm"

type TipoDestino string

const (
	TipoDestinoCasa     TipoDestino = "casa"
	TipoDestinoEdificio TipoDestino = "edificio"
)

type Destino struct {
	gorm.Model
	TenantID uint `gorm:"column:tenant_id;not null;index"`
	// Nombre es el string resuelto que viaja como casa_destino por el resto
	// del sistema (Visita, Membresia no tienen FK a Destino, solo el texto)
	// — se calcula a partir de Calle/Tipo/Numero al crear.
	Nombre   string      `gorm:"not null"`
	Calle    string      `gorm:"not null"`
	Tipo     TipoDestino `gorm:"not null;default:'casa'"`
	Numero   string      `gorm:"not null"`
	Titular  string      `gorm:"not null"`
	KioskoID *uint       `gorm:"index"`
}

func (Destino) TableName() string { return "destinos" }
