package persona

import (
	"crypto/rand"
	"errors"
	"fmt"
	"math/big"

	"golang.org/x/crypto/bcrypt"
)

// pinDigitos es el largo fijo del PIN que genera el sistema. El kiosko
// sigue aceptando de 4 a 6 para no romper los PIN viejos que la gente
// eligió a mano antes de este cambio.
const pinDigitos = 5

// intentosPin acota la búsqueda de un código libre: con 100 000
// combinaciones y centros de cientos de casas, chocar 12 veces seguidas es
// prácticamente imposible; si pasa, es señal de que el centro se quedó sin
// espacio y conviene fallar en vez de girar para siempre.
const intentosPin = 12

var errSinPinLibre = errors.New("no se encontró un PIN libre en este centro")

// generarPin devuelve un PIN de 5 dígitos que no colisiona con ninguno de
// los ya usados en el centro, junto con su hash bcrypt. `usados` son los
// códigos en claro (membresías creadas por el sistema) y `hashesLegacy`
// los hashes de las membresías viejas, cuyo código en claro ya nadie
// conoce y solo se puede descartar comparando.
func generarPin(usados []string, hashesLegacy []string) (codigo string, hash string, err error) {
	ocupados := make(map[string]struct{}, len(usados))
	for _, u := range usados {
		ocupados[u] = struct{}{}
	}

	for i := 0; i < intentosPin; i++ {
		c, err := pinAleatorio()
		if err != nil {
			return "", "", err
		}
		if _, existe := ocupados[c]; existe {
			continue
		}
		if pinChocaConLegacy(c, hashesLegacy) {
			continue
		}
		h, err := bcrypt.GenerateFromPassword([]byte(c), bcrypt.DefaultCost)
		if err != nil {
			return "", "", err
		}
		return c, string(h), nil
	}
	return "", "", errSinPinLibre
}

// pinAleatorio saca los dígitos de crypto/rand — el PIN abre la puerta del
// fraccionamiento, así que no puede venir de una secuencia adivinable.
func pinAleatorio() (string, error) {
	max := big.NewInt(1)
	for i := 0; i < pinDigitos; i++ {
		max.Mul(max, big.NewInt(10))
	}
	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%0*d", pinDigitos, n), nil
}

func pinChocaConLegacy(codigo string, hashes []string) bool {
	for _, h := range hashes {
		if h == "" {
			continue
		}
		if bcrypt.CompareHashAndPassword([]byte(h), []byte(codigo)) == nil {
			return true
		}
	}
	return false
}
