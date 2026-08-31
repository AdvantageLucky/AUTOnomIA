package auth

import (
	"context"
	"time"

	"gorm.io/gorm"
)

// OtpSender manda el código de verificación al correo del Admin. Se declara
// aquí (en vez de importar persona.OtpSender) porque persona ya importa
// auth -- importar en la otra dirección crearía un ciclo. Cualquier valor
// que implemente Enviar(...) satisface esta interfaz sin necesidad de que
// su tipo concreto viva en este paquete (incluyendo persona.EmailOtpSender
// y persona.LogOtpSender, pasados desde router.go).
type OtpSender interface {
	Enviar(ctx context.Context, destino, codigo string) error
}

// AdminOtpSolicitud es un código de verificación pendiente para el correo de
// un Admin -- login alternativo al de correo+password, mismo patrón que
// persona.OtpSolicitud pero anclado a correo en vez de teléfono, porque el
// Admin no tiene teléfono como identidad (Correo es su identificador único,
// ver admin.Admin).
type AdminOtpSolicitud struct {
	gorm.Model
	Correo   string    `gorm:"not null;index"`
	Codigo   string    `gorm:"not null"`
	ExpiraEn time.Time `gorm:"not null"`
	Intentos int       `gorm:"not null;default:0"`
}

func (AdminOtpSolicitud) TableName() string { return "admin_otp_solicitudes" }
