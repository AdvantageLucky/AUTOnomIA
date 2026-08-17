package persona

type SolicitarOtpRequest struct {
	Telefono string `json:"telefono" binding:"required"`
}

type VerificarOtpRequest struct {
	Telefono string `json:"telefono" binding:"required"`
	Codigo   string `json:"codigo"   binding:"required,len=6"`
}

type QrResponse struct {
	PersonaID uint   `json:"persona_id"`
	Firma     string `json:"firma"`
}
