package auth

import (
	"crypto/rand"
	"fmt"
	"math/big"
)

// generarCodigoOtpAdmin genera un código numérico de 6 dígitos -- misma
// lógica que persona.generarCodigoOtp, duplicada aquí en vez de exportada
// desde persona: es una función pura de una línea, no vale la pena acoplar
// el paquete auth al paquete persona solo por esto.
func generarCodigoOtpAdmin() (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}
