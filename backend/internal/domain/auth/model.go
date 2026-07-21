/*
Package auth
DB Models

Model SesionAcceso
SesionKiosko: Representa tabla de sesiones para kioskos.
A diferencia del Admin/Residente (login stateless via JWT) el kiosko es un
dispositivo desatendido que se queda logeado mucho tiempo, asi que su sesion
se persiste en la base de datos para poder revocarla desde el dashboard

googleTokenInfo: Representa la info retornada por google services al loguearse o
registrarse a traves de google
*/
package auth

import "gorm.io/gorm"

type SesionAcceso struct {
	gorm.Model
	AccesoID uint   `gorm:"not null;index"`
	Token    string `gorm:"not null;uniqueIndex"`
	Revocada bool   `gorm:"not null;default:false"`
}

type googleTokenInfo struct {
	Aud   string `json:"aud"`
	Email string `json:"email"`
	Sub   string `json:"sub"`
}
