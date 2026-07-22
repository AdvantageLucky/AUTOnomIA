package kiosko

import (
	"crypto/rand"
	"encoding/base32"
)

// generateClaveKiosko genera una credencial aleatoria de alta entropía para un kiosko.
// Usa el alfabeto base32 estándar (A-Z, 2-7) que no tiene caracteres ambiguos (0/O, 1/I/L).
func generateClaveKiosko() (string, error) {
	b := make([]byte, 10)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return base32.StdEncoding.WithPadding(base32.NoPadding).EncodeToString(b), nil
}
