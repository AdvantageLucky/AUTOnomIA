/*
Package auth

Generacion y validacion de tokens JWT para Admins y Residentes,
y tokens opacos de sesion para Kioskos

Hay 3 tipos de token en el sistema:

1. JWT de Admin (HS256, 24h): firmado con JWT_SECRET (contiene admin_id)
y es usado en el dashboard de administracion. Generado por GenerateAdminToken Y
validado por ParseAdminToken

2. JWT de Residente (HS256, 7 dias): firmado con el mismo JWT_SECRET (contiene residente_id)
y es usado en la app del residente. Generado por GenerateResidenteToken y
validado por ParseResidenteToken

3. Token opaco de sesion de Kiosko (hex, 32 bytes / 64 chars): no es JWT ya que
se genera con generateSessionToken, se persiste en la tabla sesion_accesos y
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
	AdminID uint `json:"admin_id"`
	jwt.RegisteredClaims
}

// GenerateAdminToken firma un JWT (HS256) para el Admin autenticado, valido por adminTokenTTL
func GenerateAdminToken(adminID uint, secret string) (string, error) {
	claims := adminClaims{
		AdminID: adminID,
		RegisteredClaims: jwt.RegisteredClaims{
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(adminTokenTTL)),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

// ParseAdminToken valida la firma y vigencia de un JWT y devuelve el AdminID que contiene
func ParseAdminToken(tokenStr, secret string) (uint, error) {
	claims := &adminClaims{}

	token, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (any, error) {
		return []byte(secret), nil
	})
	if err != nil || !token.Valid {
		return 0, errors.New("token invalido o expirado")
	}

	return claims.AdminID, nil
}

// residenteClaims son los claims del JWT de un Residente autenticado en la app
type residenteClaims struct {
	ResidenteID uint `json:"residente_id"`
	jwt.RegisteredClaims
}

// GenerateResidenteToken firma un JWT (HS256) para el Residente autenticado, válido 7 días
func GenerateResidenteToken(residenteID uint, secret string) (string, error) {
	claims := residenteClaims{
		ResidenteID: residenteID,
		RegisteredClaims: jwt.RegisteredClaims{
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(7 * 24 * time.Hour)),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

// ParseResidenteToken valida el JWT del residente y devuelve el ResidenteID
func ParseResidenteToken(tokenStr, secret string) (uint, error) {
	claims := &residenteClaims{}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (any, error) {
		return []byte(secret), nil
	})
	if err != nil || !token.Valid {
		return 0, errors.New("token invalido o expirado")
	}
	return claims.ResidenteID, nil
}

// generateSessionToken genera un token opaco de alta entropia para una sesion de kiosko
func generateSessionToken() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}
