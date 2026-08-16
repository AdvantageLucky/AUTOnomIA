package persona

import "kigo-autonomia-backend/internal/domain/residente"

// GrupoBackfill une una Persona con todas sus Membresias — mantiene la
// vinculación explícita para que la Tarea 6 pueda asignar el ID real de la
// Persona (asignado por la base de datos al guardarla) a cada Membresia
// antes de guardarlas.
type GrupoBackfill struct {
	Persona    Persona
	Membresias []residente.Membresia
}

type ResultadoBackfill struct {
	Grupos   []GrupoBackfill
	Omitidos []residente.Residente
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
		g := GrupoBackfill{
			Persona: Persona{
				Telefono:             telefono,
				Nombre:               primero.Nombre,
				ApellidoPaterno:      primero.ApellidoPaterno,
				ApellidoMaterno:      primero.ApellidoMaterno,
				Embedding:            primero.Embedding,
				FotoCaraUrl:          primero.FotoCaraUrl,
				TelefonoVerificadoAt: &primero.CreatedAt,
			},
		}

		for _, r := range grupo {
			g.Membresias = append(g.Membresias, residente.Membresia{
				TenantID:        r.TenantID,
				CasaDestino:     r.CasaDestino,
				Pin:             r.Pin,
				Rol:             residente.MembresiaRolTitular,
				Status:          r.Status,
				KioskoID:        r.KioskoID,
				TiempoEsperaMin: r.TiempoEsperaMin,
			})
		}

		resultado.Grupos = append(resultado.Grupos, g)
	}

	return resultado
}
