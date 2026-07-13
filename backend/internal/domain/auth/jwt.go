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

	token, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (interface{}, error) {
		return []byte(secret), nil
	})
	if err != nil || !token.Valid {
		return 0, errors.New("token invalido o expirado")
	}

	return claims.AdminID, nil
}

// generateSessionToken genera un token opaco de alta entropia para una sesion de kiosko
func generateSessionToken() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}
