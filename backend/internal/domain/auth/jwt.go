/*
Package auth

Generacion y validacion de tokens JWT para Admins y Residentes,
y tokens opacos de sesion para Kioskos

Hay 3 tipos de token en el sistema:

1. JWT de Admin (HS256, 24h): firmado con JWT_SECRET (contiene admin_id y tenant_id)
y es usado en el dashboard de administracion. Generado por GenerateAdminToken y
validado por ParseAdminToken

2. JWT de Residente (HS256, 7 dias): firmado con el mismo JWT_SECRET (contiene residente_id y tenant_id)
y es usado en la app del residente. Generado por GenerateResidenteToken y
validado por ParseResidenteToken

3. Token opaco de sesion de Kiosko (hex, 32 bytes / 64 chars): no es JWT ya que
se genera con generateSessionToken, se persiste en la tabla sesion_kioskos y
se valida contra DB en cada request del kiosko (ver repository.go y middleware.go)
A diferencia de los JWT, puede revocarse explicitamente
*/
package auth

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// 24 horas
const adminTokenTTL = 24 * time.Hour

// adminClaims son los claims del JWT de un Admin logeado en el dashboard
type adminClaims struct {
	AdminID  uint   `json:"admin_id"`
	Rol      string `json:"rol"`
	TenantID uint   `json:"tenant_id"`
	jwt.RegisteredClaims
}

// GenerateAdminToken firma un JWT (HS256) para el Admin autenticado, valido por adminTokenTTL
func GenerateAdminToken(adminID uint, rol string, tenantID uint, secret string) (string, error) {
	claims := adminClaims{
		AdminID:  adminID,
		Rol:      rol,
		TenantID: tenantID,
		RegisteredClaims: jwt.RegisteredClaims{
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(adminTokenTTL)),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

// ParseAdminToken valida la firma y vigencia de un JWT y devuelve (adminID, rol, tenantID, error)
func ParseAdminToken(tokenStr, secret string) (uint, string, uint, error) {
	claims := &adminClaims{}

	token, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (any, error) {
		return []byte(secret), nil
	})
	if err != nil || !token.Valid {
		return 0, "", 0, errors.New("token invalido o expirado")
	}

	return claims.AdminID, claims.Rol, claims.TenantID, nil
}


// personaClaims son los claims del JWT de una Persona autenticada en la app
// Kigo — a diferencia de admin/residente, Persona no lleva tenant_id: es
// una identidad global (ver spec 2026-08-16-persona-identidad-kigo-design.md §2).
type personaClaims struct {
	PersonaID uint `json:"persona_id"`
	jwt.RegisteredClaims
}

// GeneratePersonaToken firma un JWT (HS256) para la Persona autenticada, válido 30 días
func GeneratePersonaToken(personaID uint, secret string) (string, error) {
	claims := personaClaims{
		PersonaID: personaID,
		RegisteredClaims: jwt.RegisteredClaims{
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(30 * 24 * time.Hour)),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

// ParsePersonaToken valida el JWT de la Persona y devuelve su personaID
func ParsePersonaToken(tokenStr, secret string) (uint, error) {
	claims := &personaClaims{}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (any, error) {
		return []byte(secret), nil
	})
	if err != nil || !token.Valid || claims.PersonaID == 0 {
		return 0, errors.New("token invalido o expirado")
	}
	return claims.PersonaID, nil
}

// generateSessionToken genera un token opaco de alta entropia para una sesion de kiosko
func generateSessionToken() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}
