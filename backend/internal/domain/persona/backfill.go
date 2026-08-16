package persona

import "kigo-autonomia-backend/internal/domain/residente"

type ResultadoBackfill struct {
	Personas   []Persona
	Membresias []residente.Membresia
	Omitidos   []residente.Residente
}

// ConstruirBackfill agrupa Residentes existentes por teléfono: cada grupo se
// vuelve una sola Persona más una Membresia por cada Residente del grupo.
// Los Residente sin teléfono no se pueden convertir sin inventar un dato —
// se dejan en Omitidos para que alguien los revise a mano (ver spec §6).
func ConstruirBackfill(residentes []residente.Residente) ResultadoBackfill {
	var resultado ResultadoBackfill
	porTelefono := map[string][]residente.Residente{}

	for _, r := range residentes {
		if r.Telefono == "" {
			resultado.Omitidos = append(resultado.Omitidos, r)
			continue
		}
		porTelefono[r.Telefono] = append(porTelefono[r.Telefono], r)
	}

	for telefono, grupo := range porTelefono {
		primero := grupo[0]
		p := Persona{
			Telefono:             telefono,
			Nombre:               primero.Nombre,
			ApellidoPaterno:      primero.ApellidoPaterno,
			ApellidoMaterno:      primero.ApellidoMaterno,
			Embedding:            primero.Embedding,
			FotoCaraUrl:          primero.FotoCaraUrl,
			TelefonoVerificadoAt: &primero.CreatedAt,
		}
		resultado.Personas = append(resultado.Personas, p)

		for _, r := range grupo {
			resultado.Membresias = append(resultado.Membresias, residente.Membresia{
				TenantID:        r.TenantID,
				CasaDestino:     r.CasaDestino,
				Pin:             r.Pin,
				Rol:             residente.MembresiaRolTitular,
				Status:          r.Status,
				KioskoID:        r.KioskoID,
				TiempoEsperaMin: r.TiempoEsperaMin,
			})
		}
	}

	return resultado
}
