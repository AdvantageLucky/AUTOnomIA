package persona

import "strings"

// NormalizarTelefono reduce un teléfono a solo dígitos y se queda con los
// últimos 10 (formato local mexicano) -- sin esto, "222 123 4567",
// "222-123-4567" y "+522221234567" son tres strings distintos para
// FindByTelefono/FindOrCreateByTelefono, así que la misma persona termina
// repartida en Persona rows distintas según quién haya tecleado su
// teléfono y cómo. Esto rompía en concreto: una invitación creada con el
// teléfono en un formato nunca aparecía en "recibidas" para esa persona
// si ella se había registrado con el mismo número en otro formato.
func NormalizarTelefono(raw string) string {
	var b strings.Builder
	for _, r := range raw {
		if r >= '0' && r <= '9' {
			b.WriteRune(r)
		}
	}
	digits := b.String()
	if len(digits) > 10 {
		digits = digits[len(digits)-10:]
	}
	return digits
}
