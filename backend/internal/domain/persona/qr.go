package persona

import (
	"crypto/ed25519"
	"encoding/hex"
	"strconv"
)

// FirmarPersonaID firma un persona_id con la clave privada Ed25519 del
// sistema — esto es lo que va dentro del QR personal (persona_id + esta
// firma). El kiosko verifica offline con la clave pública correspondiente,
// que nunca permite forjar una firma nueva (ver spec §1).
func FirmarPersonaID(personaID uint, privKey ed25519.PrivateKey) string {
	mensaje := []byte(strconv.FormatUint(uint64(personaID), 10))
	firma := ed25519.Sign(privKey, mensaje)
	return hex.EncodeToString(firma)
}

// VerificarFirma confirma que `firmaHex` es una firma Ed25519 válida de
// `personaID` bajo `pubKey`. Un hex mal formado se trata como firma
// inválida, no como error.
func VerificarFirma(personaID uint, firmaHex string, pubKey ed25519.PublicKey) bool {
	firma, err := hex.DecodeString(firmaHex)
	if err != nil {
		return false
	}
	mensaje := []byte(strconv.FormatUint(uint64(personaID), 10))
	return ed25519.Verify(pubKey, mensaje, firma)
}
