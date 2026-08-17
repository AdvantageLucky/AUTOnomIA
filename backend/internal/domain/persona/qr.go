package persona

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"strconv"
)

// FirmarPersonaID calcula la firma HMAC-SHA256 de un persona_id con la
// llave maestra del sistema — esto es lo que va dentro del QR personal
// (persona_id + esta firma). Cualquier kiosko que traiga la misma llave
// maestra puede verificar la firma offline, sin conocer nada más sobre esa
// Persona en particular (ver spec §3/§10).
func FirmarPersonaID(personaID uint, llaveMaestra string) string {
	mac := hmac.New(sha256.New, []byte(llaveMaestra))
	mac.Write([]byte(strconv.FormatUint(uint64(personaID), 10)))
	return hex.EncodeToString(mac.Sum(nil))
}

// VerificarFirma confirma que `firma` corresponde a `personaID` firmado con
// `llaveMaestra` — usa hmac.Equal (comparación en tiempo constante) para no
// filtrar la firma correcta por temporización.
func VerificarFirma(personaID uint, firma, llaveMaestra string) bool {
	esperada := FirmarPersonaID(personaID, llaveMaestra)
	return hmac.Equal([]byte(firma), []byte(esperada))
}
