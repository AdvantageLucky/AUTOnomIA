/*
Package auth

Paquete de estructuras que representan respuestas o peticiones relacionadas con
el login/sign-in de Admin (JWT/Google), verificación de correo por OTP,
recuperación de contraseña y login de Kiosko (sesión persistida)
*/
package auth

// RegisterRequest DTO para registrar un nuevo Admin
type RegisterRequest struct {
	Correo          string `json:"correo"           binding:"required,email"`
	Password        string `json:"password"         binding:"required,min=8"`
	Nombre          string `json:"nombre"`
	ApellidoPaterno string `json:"apellido_paterno"`
	Rol             string `json:"rol"` // "admin" (default) o "vigilante" si el solicitante es admin
	Codigo          string `json:"codigo"` // Código OTP para verificar correo en sign-in
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

// SolicitarOtpAdminRequest DTO para pedir un código OTP por correo
// Usado en Sign-in (verificación de correo) y en Recuperar contraseña
type SolicitarOtpAdminRequest struct {
	Correo string `json:"correo" binding:"required,email"`
}

// RecuperarPasswordRequest DTO para restablecer la contraseña con OTP
type RecuperarPasswordRequest struct {
	Correo      string `json:"correo"       binding:"required,email"`
	Codigo      string `json:"codigo"       binding:"required"`
	NewPassword string `json:"new_password" binding:"required,min=8"`
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
