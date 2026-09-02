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
	return smtpSend(s.Host, s.Port, s.User, s.Password, destino, asunto, cuerpo)
}

// EmailSender manda un correo con asunto y cuerpo libres — a diferencia de
// OtpSender, que solo sabe mandar códigos. Se usa para alertas al admin
// (p. ej. una visita sin residente al que avisar).
type EmailSender interface {
	Enviar(ctx context.Context, destino, asunto, cuerpo string) error
}

// LogEmailSender es el EmailSender falso que solo loguea — mismo rol que
// LogOtpSender mientras no haya SMTP configurado.
type LogEmailSender struct{}

func (LogEmailSender) Enviar(_ context.Context, destino, asunto, cuerpo string) error {
	log.Printf("[email-fake] a %s: %s — %s", destino, asunto, cuerpo)
	return nil
}

// SMTPEmailSender manda el correo de verdad, reusando las mismas credenciales
// SMTP que EmailOtpSender.
type SMTPEmailSender struct {
	Host     string
	Port     string
	User     string
	Password string
}

func (s SMTPEmailSender) Enviar(_ context.Context, destino, asunto, cuerpo string) error {
	return smtpSend(s.Host, s.Port, s.User, s.Password, destino, asunto, cuerpo)
}

func smtpSend(host, port, user, password, destino, asunto, cuerpo string) error {
	msg := fmt.Sprintf("From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n%s", user, destino, asunto, cuerpo)
	auth := smtp.PlainAuth("", user, password, host)
	addr := fmt.Sprintf("%s:%s", host, port)
	return smtp.SendMail(addr, auth, user, []string{destino}, []byte(msg))
}
