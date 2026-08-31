package persona

import (
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"

	"kigo-autonomia-backend/internal/platform/ctxkeys"
)

// estadosFallaKigo son los estados terminales de falla que reporta Kigo. El
// resto (CONSENT_GIVEN, LIVENESS_STARTED, LIVENESS_COMPLETED...) son
// intermedios y se traducen a PENDING para que la app siga esperando.
var estadosFallaKigo = map[string]bool{
	"LIVENESS_FAILED": true,
	"QUALITY_FAILED":  true,
	"EXPIRED":         true,
	"FAILED":          true,
}

// IniciarKigoVerify crea un enrollment nuevo en Kigo Verify para la Persona
// autenticada. No hay limite de un enrollment por Persona: cada llamada crea
// uno nuevo, para que un intento atorado no bloquee reintentar (ver spec,
// seccion 6 "Usuario cierra la app a medio proceso").
func (h *Handler) IniciarKigoVerify(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)

	if h.kigoVerify.APIKey == "" {
		// Sin llave, Kigo contesta 401 y el usuario veria un "intenta de
		// nuevo" que nunca va a funcionar. Es un error de despliegue, no del
		// usuario: se distingue para que se note en logs/monitoreo.
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "la verificacion con Kigo no esta configurada en este servidor"})
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 15*time.Second)
	defer cancel()

	// metadata regresa verbatim en el webhook: lleva telefono y nombre para
	// poder reconciliar una entrega sin volver a consultar la base.
	metadata := map[string]any{"persona_id": personaID}
	if p, err := h.repo.FindByID(personaID); err == nil {
		metadata["phone"] = p.Telefono
		if nombre := strings.TrimSpace(p.Nombre + " " + p.ApellidoPaterno); nombre != "" {
			metadata["nombre"] = nombre
		}
	}

	externalRef := fmt.Sprintf("persona-%d-%d", personaID, time.Now().UnixNano())
	enrollmentID, enrollmentURL, webhookSecret, expiresAt, err := crearEnrollmentKigo(ctx, h.kigoVerify, externalRef, metadata)
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

	// redirect_url se devuelve para que kigo-app vigile exactamente el mismo
	// centinela que le mandamos a Kigo. Tenerlo hardcodeado en las dos puntas
	// dejaba que se separaran en silencio y el WebView no cerraba nunca.
	c.JSON(http.StatusOK, gin.H{
		"enrollment_id":  enrollmentID,
		"enrollment_url": enrollmentURL,
		"redirect_url":   h.kigoVerify.redirectURL(),
	})
}

// ConsultarEstadoKigoVerify resuelve el estado de un enrollment para que
// kigo-app haga polling.
//
// Esta ruta es autosuficiente a proposito: si Kigo ya reporta COMPLETED, aqui
// mismo se descarga la foto y se cierra el enrollment, sin esperar al webhook.
// Antes COMPLETED solo se escribia desde el webhook, asi que una entrega
// perdida — o una firma que no cuadrara — dejaba el flujo colgado para
// siempre. El webhook es un atajo, no un requisito.
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

	// 25s: la consulta puede encadenar la descarga de la foto cuando Kigo ya
	// reporta COMPLETED, no solo el GET de estado.
	ctx, cancel := context.WithTimeout(c.Request.Context(), 25*time.Second)
	defer cancel()
	statusKigo, err := consultarEnrollmentKigo(ctx, h.kigoVerify, enrollmentID)
	if err != nil {
		// Kigo no respondio -- no es una falla del enrollment en si, se
		// reporta PENDING y kigo-app reintenta en el siguiente poll.
		c.JSON(http.StatusOK, gin.H{"status": "PENDING"})
		return
	}
	if estadosFallaKigo[statusKigo] {
		h.kigoVerifyRepo.ActualizarEstado(e.ID, "FAILED")
		c.JSON(http.StatusOK, gin.H{"status": "FAILED"})
		return
	}
	if statusKigo == "COMPLETED" {
		fotoURL, err := h.finalizarEnrollment(ctx, e)
		if err != nil {
			// La foto existe del lado de Kigo pero no la pudimos traer.
			// PENDING deja que el siguiente poll lo reintente, en vez de
			// quemar el enrollment por un fallo transitorio de red.
			c.JSON(http.StatusOK, gin.H{"status": "PENDING"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "COMPLETED", "foto_url": fotoURL})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "PENDING"})
}

// WebhookKigoVerify recibe el evento EnrollmentCompleted de Kigo Verify.
// Publico -- lo llama Kigo, no un usuario nuestro -- por eso la verificacion
// de la firma reemplaza al middleware de auth de siempre.
//
// Es un atajo sobre el polling, no la unica ruta: si la firma no cuadra o la
// entrega se pierde, ConsultarEstadoKigoVerify cierra el enrollment igual.
func (h *Handler) WebhookKigoVerify(c *gin.Context) {
	// El cuerpo crudo se necesita para el HMAC, que se calcula sobre los
	// bytes exactos: re-serializar el JSON ya parseado reordena las llaves y
	// el digest deja de coincidir.
	raw, err := c.GetRawData()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "cuerpo ilegible"})
		return
	}

	var body struct {
		EnrollmentID string `json:"enrollment_id"`
	}
	if err := json.Unmarshal(raw, &body); err != nil || body.EnrollmentID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "enrollment_id requerido"})
		return
	}

	e, err := h.kigoVerifyRepo.FindByEnrollmentID(body.EnrollmentID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "enrollment no encontrado"})
		return
	}

	if !firmaWebhookValida(c.Request.Header, raw, e.WebhookSecret) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "firma invalida"})
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 20*time.Second)
	defer cancel()
	if _, err := h.finalizarEnrollment(ctx, e); err != nil {
		// 5xx a proposito: Kigo reintenta la entrega. Un 200 aqui la daria
		// por buena y perderiamos la foto.
		c.JSON(http.StatusInternalServerError, gin.H{"error": "no se pudo completar el enrollment"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"ok": true})
}

// finalizarEnrollment descarga la foto de Kigo, la guarda como nuestra y
// cierra el enrollment como COMPLETED. La llaman las dos rutas (webhook y
// polling), que pueden correr a la vez: MarcarCompletado hace compare-and-set
// y devuelve la URL que quedo, asi que quien pierde la carrera responde con
// la foto del que gano en vez de pisarla.
func (h *Handler) finalizarEnrollment(ctx context.Context, e *KigoVerifyEnrollment) (string, error) {
	fotoBytes, err := descargarFotoKigo(ctx, h.kigoVerify, e.EnrollmentID)
	if err != nil {
		return "", err
	}

	fotoURL, err := guardarFotoKigoVerify(fotoBytes, h.uploadsDir, h.kigoVerify.PublicURL)
	if err != nil {
		return "", err
	}

	return h.kigoVerifyRepo.MarcarCompletado(e.ID, fotoURL)
}

// firmaWebhookValida acepta los dos esquemas que puede traer la entrega.
//
// El principal es X-Kigo-Signature: HMAC-SHA256 del cuerpo crudo con el
// webhook_secret, en hex o base64 y con el prefijo "sha256=" opcional — las
// tres variantes son comunes y no tenemos confirmado cual usa Kigo (el
// esquema exacto no esta documentado, ver Global Constraints del plan).
//
// El de respaldo es X-Webhook-Secret con el secreto en claro, que es lo que
// este handler asumia antes. Se conserva para no romper un despliegue que ya
// dependa de el; ata menos que el HMAC (no cubre el cuerpo), pero el handler
// no confia en el cuerpo mas alla del enrollment_id: la foto y el estado se
// vuelven a pedir a Kigo con nuestra propia api-key.
func firmaWebhookValida(headers http.Header, body []byte, secret string) bool {
	if secret == "" {
		return false
	}

	if firma := strings.TrimSpace(headers.Get("X-Kigo-Signature")); firma != "" {
		mac := hmac.New(sha256.New, []byte(secret))
		mac.Write(body)
		esperado := mac.Sum(nil)

		// "sha256=abc..." y "abc..." se tratan igual
		if strings.HasPrefix(strings.ToLower(firma), "sha256") {
			if i := strings.IndexByte(firma, byte('=')); i >= 0 {
				firma = firma[i+1:]
			}
		}
		if recibido, err := hex.DecodeString(firma); err == nil && hmac.Equal(recibido, esperado) {
			return true
		}
		if recibido, err := base64.StdEncoding.DecodeString(firma); err == nil && hmac.Equal(recibido, esperado) {
			return true
		}
		return false
	}

	if plano := headers.Get("X-Webhook-Secret"); plano != "" {
		return subtle.ConstantTimeCompare([]byte(plano), []byte(secret)) == 1
	}
	return false
}

// guardarFotoKigoVerify guarda bytes crudos (ya descargados de Kigo, no un
// multipart.FileHeader) -- no puede reusar visitas.GuardarFotoVisitante,
// que esta construido especificamente sobre gin.Context.SaveUploadedFile.
//
// La URL se arma con PublicURL, no con el Host de la peticion: quien llama
// puede ser Kigo (webhook) o la app (polling), y cada uno ve un host distinto
// — la foto quedaba con una URL que dependia de quien la disparo.
func guardarFotoKigoVerify(fotoBytes []byte, dir, publicURL string) (string, error) {
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	nombreArchivo := hex.EncodeToString(b) + ".jpg"
	if err := os.WriteFile(filepath.Join(dir, nombreArchivo), fotoBytes, 0644); err != nil {
		return "", err
	}
	return strings.TrimRight(publicURL, "/") + "/uploads/visitantes/" + nombreArchivo, nil
}
