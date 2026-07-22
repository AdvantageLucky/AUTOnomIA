/*
Package auth

Paquete de estructuras que representan respuestas o peticiones relacionadas con
el login de Admin (JWT/Google) y de Kiosko (sesion persistida)
*/
package auth

// RegisterRequest DTO para registrar un nuevo Admin
type RegisterRequest struct {
	Correo   string `json:"correo"   binding:"required,email"`
	Password string `json:"password" binding:"required,min=8"`
}

// LoginRequest DTO para loguear a un Admin existente
type LoginRequest struct {
	Correo   string `json:"correo"   binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// JWTResponse DTO de respuesta para login/registro de Admin
type JWTResponse struct {
	AccessToken string `json:"access_token"`
}

// LoginKioskoRequest DTO para loguear a un kiosko usando el KioskoID y su ClaveKiosko
type LoginKioskoRequest struct {
	KioskoID    uint   `json:"kiosko_id"    binding:"required"`
	ClaveKiosko string `json:"clave_kiosko" binding:"required"`
}

// SesionResponse DTO de respuesta para el login de un kiosko
type SesionResponse struct {
	Token string `json:"token"`
}

// GoogleLoginRequest DTO para login con Google Identity Services
type GoogleLoginRequest struct {
	Credential string `json:"credential" binding:"required"` // id_token del popup de Google
}
