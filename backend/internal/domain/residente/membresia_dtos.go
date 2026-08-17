package residente

type MembresiaAdminResponse struct {
	ID          uint   `json:"id"`
	PersonaID   uint   `json:"persona_id"`
	CasaDestino string `json:"casa_destino"`
	Rol         string `json:"rol"`
	Status      string `json:"status"`
}

func toMembresiaAdminResponse(m Membresia) MembresiaAdminResponse {
	return MembresiaAdminResponse{
		ID:          m.ID,
		PersonaID:   m.PersonaID,
		CasaDestino: m.CasaDestino,
		Rol:         m.Rol,
		Status:      m.Status,
	}
}
