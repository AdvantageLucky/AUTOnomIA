package visitas

import "context"

// Notificador avisa al anfitrión (residente) de la casa destino que llegó una
// visita que necesita su autorización. Interfaz definida aquí (no en
// residente/) para evitar un ciclo de imports: residente/ ya depende de
// visitas/ para crear registros de Visita.
type Notificador interface {
	NotificarNuevaVisita(ctx context.Context, tenantID uint, casaDestino string, v Visita) error
}

// NotificadorNulo no hace nada — valor por defecto si el handler se
// construye sin uno explícito (p. ej. en tests).
type NotificadorNulo struct{}

func (NotificadorNulo) NotificarNuevaVisita(context.Context, uint, string, Visita) error {
	return nil
}
