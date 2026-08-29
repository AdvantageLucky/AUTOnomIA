package persona

import (
	"context"
	"crypto/rand"
	"crypto/subtle"
	"encoding/hex"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/gin-gonic/gin"

	"kigo-autonomia-backend/internal/platform/ctxkeys"
)

// IniciarKigoVerify crea un enrollment nuevo en Kigo Verify para la Persona
// autenticada. No hay limite de un enrollment por Persona: cada llamada crea
// uno nuevo, para que un intento atorado no bloquee reintentar (ver spec,
// seccion 6 "Usuario cierra la app a medio proceso").
func (h *Handler) IniciarKigoVerify(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)

	ctx, cancel := context.WithTimeout(c.Request.Context(), 15*time.Second)
	defer cancel()

	externalRef := fmt.Sprintf("persona-%d-%d", personaID, time.Now().UnixNano())
	enrollmentID, enrollmentURL, webhookSecret, expiresAt, err := crearEnrollmentKigo(ctx, h.kigoVerify, externalRef)
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"error": "no se pudo iniciar la verificacion con Kigo"})
		return
	}

	if err := h.kigoVerifyRepo.Crear(&KigoVerifyEnrollment{
		PersonaID:     personaID,
		EnrollmentID:  enrollmentID,
		WebhookSecret: webhookSecret,
		Status:        "PENDING",
		ExpiresAt:     expiresAt,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"enrollment_id": enrollmentID, "enrollment_url": enrollmentURL})
}

// ConsultarEstadoKigoVerify resuelve el estado de un enrollment para que
// kigo-app haga polling. No depende solo del webhook: si sigue PENDING,
// primero revisa si ya expiro (sin llamar a Kigo) y si no, consulta
// activamente a Kigo por si hubo una falla que su webhook no reporto (no
// esta confirmado que Kigo webhookee fallas, ver spec seccion 6).
func (h *Handler) ConsultarEstadoKigoVerify(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)
	enrollmentID := c.Query("enrollment_id")
	if enrollmentID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "enrollment_id requerido"})
		return
	}

	e, err := h.kigoVerifyRepo.FindByPersonaAndEnrollmentID(personaID, enrollmentID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "enrollment no encontrado"})
		return
	}

	if e.Status == "COMPLETED" {
		c.JSON(http.StatusOK, gin.H{"status": "COMPLETED", "foto_url": e.FotoRostroURL})
		return
	}
	if e.Status == "FAILED" {
		c.JSON(http.StatusOK, gin.H{"status": "FAILED"})
		return
	}

	// PENDING: primero expiracion local, sin llamar a Kigo
	if time.Now().After(e.ExpiresAt) {
		h.kigoVerifyRepo.ActualizarEstado(e.ID, "FAILED")
		c.JSON(http.StatusOK, gin.H{"status": "FAILED"})
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()
	statusKigo, err := consultarEnrollmentKigo(ctx, h.kigoVerify, enrollmentID)
	if err != nil {
		// Kigo no respondio -- no es una falla del enrollment en si, se
		// reporta PENDING y kigo-app reintenta en el siguiente poll.
		c.JSON(http.StatusOK, gin.H{"status": "PENDING"})
		return
	}
	if statusKigo == "LIVENESS_FAILED" || statusKigo == "QUALITY_FAILED" {
		h.kigoVerifyRepo.ActualizarEstado(e.ID, "FAILED")
		c.JSON(http.StatusOK, gin.H{"status": "FAILED"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "PENDING"})
}

// WebhookKigoVerify recibe el evento EnrollmentCompleted de Kigo Verify.
// Publico -- lo llama Kigo, no un usuario nuestro -- por eso la verificacion
// de la firma reemplaza al middleware de auth de siempre.
//
// NOTA: el mecanismo exacto de firma no esta confirmado contra el webhook
// real de Kigo (ver Global Constraints del plan) -- este handler asume un
// header X-Webhook-Secret con el valor en texto plano.
func (h *Handler) WebhookKigoVerify(c *gin.Context) {
	var body struct {
		EnrollmentID string `json:"enrollment_id"`
	}
	if err := c.ShouldBindJSON(&body); err != nil || body.EnrollmentID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "enrollment_id requerido"})
		return
	}

	e, err := h.kigoVerifyRepo.FindByEnrollmentID(body.EnrollmentID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "enrollment no encontrado"})
		return
	}

	firmaRecibida := c.GetHeader("X-Webhook-Secret")
	if subtle.ConstantTimeCompare([]byte(firmaRecibida), []byte(e.WebhookSecret)) != 1 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "firma invalida"})
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 20*time.Second)
	defer cancel()
	fotoBytes, err := descargarFotoKigo(ctx, h.kigoVerify, body.EnrollmentID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "no se pudo descargar la foto de Kigo"})
		return
	}

	fotoURL, err := guardarFotoKigoVerify(c, fotoBytes, h.uploadsDir)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err := h.kigoVerifyRepo.ActualizarCompletado(e.ID, fotoURL); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"ok": true})
}

// guardarFotoKigoVerify guarda bytes crudos (ya descargados de Kigo, no un
// multipart.FileHeader) -- no puede reusar visitas.GuardarFotoVisitante,
// que esta construido especificamente sobre gin.Context.SaveUploadedFile.
func guardarFotoKigoVerify(c *gin.Context, fotoBytes []byte, dir string) (string, error) {
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	nombreArchivo := hex.EncodeToString(b) + ".jpg"
	if err := os.WriteFile(filepath.Join(dir, nombreArchivo), fotoBytes, 0644); err != nil {
		return "", err
	}
	scheme := "http"
	if c.Request.TLS != nil {
		scheme = "https"
	}
	return fmt.Sprintf("%s://%s/uploads/visitantes/%s", scheme, c.Request.Host, nombreArchivo), nil
}
