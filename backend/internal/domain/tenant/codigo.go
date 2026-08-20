package tenant

import "strings"

var acentos = strings.NewReplacer(
	"á", "a", "é", "e", "í", "i", "ó", "o", "ú", "u", "ü", "u", "ñ", "n",
	"Á", "A", "É", "E", "Í", "I", "Ó", "O", "Ú", "U", "Ü", "U", "Ñ", "N",
)

const codigoLongitudMax = 30

// GenerarCodigo deriva el código público de un centro a partir de su nombre:
// sin acentos, en mayúsculas, solo letras/dígitos separados por guiones. No
// resuelve colisiones — eso es responsabilidad de quien la llama, porque
// requiere acceso al repositorio (ver PatchTenant).
func GenerarCodigo(nombre string) string {
	plano := acentos.Replace(strings.ToUpper(strings.TrimSpace(nombre)))

	var b strings.Builder
	ultimoFueGuion := true // evita un guion al inicio
	for _, r := range plano {
		switch {
		case (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9'):
			b.WriteRune(r)
			ultimoFueGuion = false
		case !ultimoFueGuion:
			b.WriteRune('-')
			ultimoFueGuion = true
		}
	}

	codigo := strings.TrimRight(b.String(), "-")
	if len(codigo) > codigoLongitudMax {
		codigo = strings.TrimRight(codigo[:codigoLongitudMax], "-")
	}
	if codigo == "" {
		codigo = "CENTRO"
	}
	return codigo
}
