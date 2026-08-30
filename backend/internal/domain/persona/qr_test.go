package persona

import (
	"crypto/ed25519"
	"testing"
)

func TestFirmarPersonaID_VerificaConLaMismaLlave(t *testing.T) {
	pub, priv, _ := ed25519.GenerateKey(nil)
	firma := FirmarPersonaID(42, priv)
	if !VerificarFirma(42, firma, pub) {
		t.Error("esperaba que la firma verificara con la misma llave y el mismo persona_id")
	}
}

func TestVerificarFirma_LlaveDistinta_Falla(t *testing.T) {
	_, priv, _ := ed25519.GenerateKey(nil)
	otraPub, _, _ := ed25519.GenerateKey(nil)
	firma := FirmarPersonaID(42, priv)
	if VerificarFirma(42, firma, otraPub) {
		t.Error("una firma hecha con otra llave no debería verificar")
	}
}

func TestVerificarFirma_PersonaIDDistinto_Falla(t *testing.T) {
	pub, priv, _ := ed25519.GenerateKey(nil)
	firma := FirmarPersonaID(42, priv)
	if VerificarFirma(99, firma, pub) {
		t.Error("la firma de la persona 42 no debería verificar para la persona 99")
	}
}

func TestVerificarFirma_HexInvalido_Falla(t *testing.T) {
	pub, _, _ := ed25519.GenerateKey(nil)
	if VerificarFirma(42, "no-es-hex-valido", pub) {
		t.Error("un string que no decodifica a hex no debería verificar")
	}
}
