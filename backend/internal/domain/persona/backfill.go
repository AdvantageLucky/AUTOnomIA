package persona

import (
	"strings"

	"kigo-autonomia-backend/internal/domain/residente"
)

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

// normalizarTelefono deja solo dígitos — "55 1234 5678" y "5512345678" deben
// agruparse como el mismo teléfono, no como dos personas distintas.
func normalizarTelefono(t string) string {
	var sb strings.Builder
	for _, c := range t {
		if c >= '0' && c <= '9' {
			sb.WriteRune(c)
		}
	}
	return sb.String()
}

// construirPersona arma los datos de la Persona a partir de todo el grupo,
// no solo del primer Residente: toma el primer Nombre/Apellido* no vacío y
// el primer Embedding no nulo (con su FotoCaraUrl correspondiente) que
// encuentre en el grupo, para no perder silenciosamente el rostro
// capturado de un residente solo porque otro del mismo teléfono aparece
// primero en el slice sin haberlo capturado.
func construirPersona(telefono string, grupo []residente.Residente) Persona {
	p := Persona{
		Telefono:             telefono,
		TelefonoVerificadoAt: &grupo[0].CreatedAt,
	}
	for _, r := range grupo {
		if p.Nombre == "" && r.Nombre != "" {
			p.Nombre = r.Nombre
		}
		if p.ApellidoPaterno == "" && r.ApellidoPaterno != "" {
			p.ApellidoPaterno = r.ApellidoPaterno
		}
		if p.ApellidoMaterno == "" && r.ApellidoMaterno != "" {
			p.ApellidoMaterno = r.ApellidoMaterno
		}
		if p.Embedding == nil && r.Embedding != nil {
			p.Embedding = r.Embedding
			p.FotoCaraUrl = r.FotoCaraUrl
		}
	}
	return p
}

// ConstruirBackfill agrupa Residentes existentes por teléfono normalizado:
// cada grupo se vuelve una sola Persona más una Membresia por cada
// Residente del grupo. Los Residente sin teléfono no se pueden convertir
// sin inventar un dato — se dejan en Omitidos para que alguien los revise
// a mano (ver spec §6). Si dos Residente del MISMO grupo (mismo teléfono)
// pertenecen también al MISMO tenant, el primero se queda con la
// Membresia y los siguientes se omiten — crear dos Membresias idénticas
// (mismo persona_id + tenant_id) violaría el índice único que las
// modela como una relación 1:1.
func ConstruirBackfill(residentes []residente.Residente) ResultadoBackfill {
	var resultado ResultadoBackfill
	porTelefono := map[string][]residente.Residente{}

	for _, r := range residentes {
		telefono := normalizarTelefono(r.Telefono)
		if telefono == "" {
			resultado.Omitidos = append(resultado.Omitidos, r)
			continue
		}
		porTelefono[telefono] = append(porTelefono[telefono], r)
	}

	for telefono, grupo := range porTelefono {
		g := GrupoBackfill{Persona: construirPersona(telefono, grupo)}

		tenantsVistos := map[uint]bool{}
		for _, r := range grupo {
			if tenantsVistos[r.TenantID] {
				resultado.Omitidos = append(resultado.Omitidos, r)
				continue
			}
			tenantsVistos[r.TenantID] = true

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
