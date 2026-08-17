package persona

import (
	"context"
	"log"
)

// OtpSender manda el código de verificación al teléfono de la Persona.
// Punto de integración con un proveedor de SMS real — ver LogOtpSender
// para el estado actual (mockeado, pendiente de elegir proveedor).
type OtpSender interface {
	Enviar(ctx context.Context, telefono, codigo string) error
}

// LogOtpSender es un OtpSender falso que solo loguea — se usa mientras no
// se elija un proveedor de SMS real para Kigo/AUTOnomIA. El código SÍ se
// genera y valida de verdad; solo el canal de entrega está mockeado.
type LogOtpSender struct{}

func (LogOtpSender) Enviar(_ context.Context, telefono, codigo string) error {
	log.Printf("[otp-fake] a %s: tu código Kigo es %s", telefono, codigo)
	return nil
}
