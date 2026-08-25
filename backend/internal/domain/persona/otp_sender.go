package persona

import (
	"context"
	"fmt"
	"log"
	"net/smtp"
)

// OtpSender manda el código de verificación a la Persona — por SMS (destino
// = teléfono) o por correo (destino = email), según qué implementación se
// use. El teléfono se mantiene como ancla de identidad en todo el sistema;
// esto solo decide el canal de entrega del código.
type OtpSender interface {
	Enviar(ctx context.Context, destino, codigo string) error
}

// LogOtpSender es un OtpSender falso que solo loguea — se usa mientras no
// se elija un proveedor de SMS real para Kigo/AUTOnomIA. El código SÍ se
// genera y valida de verdad; solo el canal de entrega está mockeado.
type LogOtpSender struct{}

func (LogOtpSender) Enviar(_ context.Context, destino, codigo string) error {
	log.Printf("[otp-fake] a %s: tu código Kigo es %s", destino, codigo)
	return nil
}

// EmailOtpSender manda el código por correo vía SMTP (Gmail con contraseña
// de aplicación, por ejemplo) — respaldo mientras no haya un proveedor de
// SMS configurado. Usa net/smtp de la librería estándar, sin dependencias
// nuevas.
type EmailOtpSender struct {
	Host     string
	Port     string
	User     string
	Password string
}

func (s EmailOtpSender) Enviar(_ context.Context, destino, codigo string) error {
	asunto := "Tu código de Kigo"
	cuerpo := fmt.Sprintf("Tu código de verificación es: %s\n\nExpira en unos minutos. Si tú no lo pediste, ignora este correo.", codigo)
	msg := fmt.Sprintf("From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n%s", s.User, destino, asunto, cuerpo)

	auth := smtp.PlainAuth("", s.User, s.Password, s.Host)
	addr := fmt.Sprintf("%s:%s", s.Host, s.Port)
	return smtp.SendMail(addr, auth, s.User, []string{destino}, []byte(msg))
}
