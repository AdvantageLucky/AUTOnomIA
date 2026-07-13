/*
Package auth

Paquete de modelo SesionAcceso. A diferencia del Admin (login stateless via JWT),
el kiosko es un dispositivo desatendido que se queda logeado mucho tiempo, asi que
su sesion se persiste en la base de datos para poder revocarla desde el dashboard
(ej. tablet robada o perdida) sin esperar a que expire un token.
*/
package auth

import "gorm.io/gorm"

type SesionAcceso struct {
	gorm.Model
	AccesoID uint   `gorm:"not null;index"`
	Token    string `gorm:"not null;uniqueIndex"`
	Revocada bool   `gorm:"not null;default:false"`
}
