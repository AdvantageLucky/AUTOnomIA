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

type UnirseCentroRequest struct {
	CodigoCentro string `json:"codigo_centro" binding:"required"`
	CasaDestino  string `json:"casa_destino"  binding:"required"`
	Pin          string `json:"pin"           binding:"required,min=4,max=6"`
}

type MembresiaResponse struct {
	ID          uint   `json:"id"`
	TenantID    uint   `json:"tenant_id"`
	CasaDestino string `json:"casa_destino"`
	Rol         string `json:"rol"`
	Status      string `json:"status"`
}
