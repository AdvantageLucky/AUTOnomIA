package persona

type SolicitarOtpRequest struct {
	Telefono string `json:"telefono" binding:"required"`
}

type VerificarOtpRequest struct {
	Telefono        string    `json:"telefono" binding:"required"`
	Codigo          string    `json:"codigo"   binding:"required,len=6"`
	Nombre          string    `json:"nombre"`
	ApellidoPaterno string    `json:"apellido_paterno"`
	ApellidoMaterno string    `json:"apellido_materno"`
	Embedding       []float64 `json:"embedding"`
}

type QrResponse struct {
	PersonaID uint   `json:"persona_id"`
	Firma     string `json:"firma"`
}
