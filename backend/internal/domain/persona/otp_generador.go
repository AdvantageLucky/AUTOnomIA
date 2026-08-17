package persona

import (
	"crypto/rand"
	"fmt"
	"math/big"
)

// generarCodigoOtp genera un código de verificación de 6 dígitos,
// criptográficamente aleatorio (crypto/rand, no math/rand).
func generarCodigoOtp() (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}
