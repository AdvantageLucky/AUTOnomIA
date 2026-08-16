package persona

import (
	"crypto/rand"
	"encoding/hex"
)

// generarQrSecreto genera un secreto aleatorio de alta entropía, usado para
// firmar (HMAC) el contenido del QR personal de la Persona — mismo patrón
// que generateSessionToken en internal/domain/auth/jwt.go.
func generarQrSecreto() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}
