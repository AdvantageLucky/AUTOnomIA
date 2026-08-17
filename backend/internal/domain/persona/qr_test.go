package persona

import "testing"

func TestFirmarPersonaID_VerificaConLaMismaLlave(t *testing.T) {
	firma := FirmarPersonaID(42, "llave-de-prueba")
	if !VerificarFirma(42, firma, "llave-de-prueba") {
		t.Error("esperaba que la firma verificara con la misma llave y el mismo persona_id")
	}
}

func TestVerificarFirma_LlaveDistinta_Falla(t *testing.T) {
	firma := FirmarPersonaID(42, "llave-de-prueba")
	if VerificarFirma(42, firma, "otra-llave") {
		t.Error("una firma hecha con otra llave no debería verificar")
	}
}

func TestVerificarFirma_PersonaIDDistinto_Falla(t *testing.T) {
	firma := FirmarPersonaID(42, "llave-de-prueba")
	if VerificarFirma(99, firma, "llave-de-prueba") {
		t.Error("la firma de la persona 42 no debería verificar para la persona 99")
	}
}
