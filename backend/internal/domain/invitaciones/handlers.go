package invitaciones

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"mime/multipart"
	"net/http"
	"strconv"
	"strings"

	"kigo-autonomia-backend/internal/domain/visitas"
	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type Handler struct {
	repo       *Repository
	db         *gorm.DB
	uploadsDir string
	visitaRepo *visitas.Repository
	llmURL     string
}

func NewHandler(repo *Repository, db *gorm.DB, uploadsDir string, visitaRepo *visitas.Repository, llmURL string) *Handler {
	return &Handler{repo: repo, db: db, uploadsDir: uploadsDir, visitaRepo: visitaRepo, llmURL: llmURL}
}

func generarToken() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}

// GenerarToken expone generarToken a otros paquetes — el dominio persona
// necesita generar el token de una invitación anclada a Persona sin
// duplicar la lógica criptográfica (Token es NOT NULL y uniqueIndex).
func GenerarToken() (string, error) {
	return generarToken()
}

// ValidarInvitacion valida un token QR
// El kiosko llama este endpoint al escanear el QR para pre-llenar el formulario
//
// @Summary Validar token de invitación (kiosko)
// @Tags invitaciones
// @Produce json
// @Param token query string true "Token de la invitación"
// @Success 200 {object} ValidarInvitacionResponse
// @Failure 404 {object} map[string]string
// @Router /kioskos/{id}/invitaciones/validar [get]
func (h *Handler) ValidarInvitacion(c *gin.Context) {
	token := c.Query("token")
	if token == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "token requerido"})
		return
	}

	inv, err := h.repo.FindByToken(token)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "invitacion no valida, expirada o agotada"})
		return
	}

	// El kiosko muestra la casa destino durante el registro del invitado, así que
	// viaja resuelta y no como id.
	var casaDestino string
	h.db.Table("destinos").Select("nombre").Where("id = ?", inv.DestinoID).Scan(&casaDestino)

	c.JSON(http.StatusOK, toValidarResponse(inv, casaDestino))
}

// UsarInvitacion valida el token, crea un registro de Visita APROBADO y registra el uso
//
// Acepta un cuerpo multipart opcional con las capturas que exija la config del
// kiosko para invitados (placa, rostro, INE). Sin cuerpo funciona igual que antes.
//
// @Summary Usar invitación (kiosko)
// @Tags invitaciones
// @Accept multipart/form-data
// @Produce json
// @Param token path string true "Token de la invitación"
// @Param curp formData string false "CURP del invitado"
// @Param placa formData string false "Placa del vehículo"
// @Param foto_documento formData file false "Foto de la identificación"
// @Param foto_rostro formData file false "Foto del rostro"
// @Param foto_placa formData file false "Foto de la placa"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /kioskos/{id}/invitaciones/{token}/usar [post]
func (h *Handler) UsarInvitacion(c *gin.Context) {
	token := c.Param("token")
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

	kioskoIDStr := c.Param("id")
	kioskoID, err := strconv.ParseUint(kioskoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "kiosko id invalido"})
		return
	}

	inv, err := h.repo.FindByToken(token)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "invitacion no valida, expirada o agotada"})
		return
	}
	if inv.TenantID != tenantID {
		c.JSON(http.StatusNotFound, gin.H{"error": "invitacion no valida, expirada o agotada"})
		return
	}

	// Cuerpo opcional: un kiosko sin capturas configuradas para invitados sigue
	// mandando un POST vacio.
	var req UsarInvitacionRequest
	if strings.HasPrefix(c.ContentType(), "multipart/form-data") {
		if err := c.ShouldBind(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
	}

	var casaDestino string
	h.db.Table("destinos").Select("nombre").Where("id = ?", inv.DestinoID).Scan(&casaDestino)

	// La validacion condicional vive en visitas y es la misma que usa el registro
	// sin invitacion: asi un solo lugar decide que exige cada config de kiosko.
	visitaRepo := visitas.NewRepository(h.db).WithContext(c.Request.Context())

	if req.ClientID != "" {
		existente, err := visitaRepo.FindByClientID(tenantID, req.ClientID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		if existente != nil {
			c.JSON(http.StatusOK, gin.H{
				"titular":      existente.Titular,
				"casa_destino": existente.CasaDestino,
				"visita_id":    existente.ID,
				"estado":       existente.Estado,
				"placa":        existente.Placa,
			})
			return
		}
	}

	cfg, err := visitaRepo.GetKioskoConfig(uint(kioskoID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "no se pudo obtener la configuracion del kiosko"})
		return
	}

	tipoDocumento := visitas.DocumentoQR
	if req.FotoDocumento != nil {
		tipoDocumento = visitas.DocumentoINE
	}

	validacion := visitas.VisitaRequest{
		Titular:       inv.Titular,
		TipoVisitante: visitas.TipoConInvitacion,
		TipoDocumento: tipoDocumento,
		Curp:          req.Curp,
		CasaDestino:   casaDestino,
		Placa:         req.Placa,
		FotoDocumento: req.FotoDocumento,
		FotoRostro:    req.FotoRostro,
		FotoPlaca:     req.FotoPlaca,
	}
	tipoKiosko, err := visitaRepo.GetKioskoTipo(uint(kioskoID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "no se pudo obtener el tipo del kiosko"})
		return
	}

	if errMsg := visitas.ValidarCamposCondicionales(validacion, cfg, tipoKiosko); errMsg != "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": errMsg})
		return
	}

	fotos, errMsg, err := h.guardarFotos(c, req)
	if errMsg != "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": errMsg})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	v := &visitas.Visita{
		TenantID:         tenantID,
		Titular:          inv.Titular,
		TipoVisitante:    visitas.TipoConInvitacion,
		TipoDocumento:    tipoDocumento,
		Curp:             strings.ToUpper(strings.TrimSpace(req.Curp)),
		FotoDocumentoURL: fotos.documento,
		NitidezIneScore:  req.NitidezIneScore,
		CalidadIne:       req.CalidadIne,
		FotoRostroURL:    fotos.rostro,
		FotoPlacaURL:     fotos.placa,
		CasaDestino:      casaDestino,
		Motivo:           inv.Motivo,
		Placa:            strings.ToUpper(strings.TrimSpace(req.Placa)),
		Estado:           visitas.EstadoAprobado,
		KioskoID:         uint(kioskoID),
		ClientID:         visitas.ClientIDPtr(req.ClientID),
		PersonaID:        inv.PersonaInvitadaID,
	}
	if err := h.db.Create(v).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error registrando visita"})
		return
	}

	if err := h.repo.IncrementarUso(inv.ID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"titular":      inv.Titular,
		"casa_destino": casaDestino,
		"visita_id":    v.ID,
		"estado":       v.Estado,
		"placa":        v.Placa,
	})

	go visitas.AnalizarYGuardarInformativo(h.visitaRepo, tenantID, *v, h.llmURL)
}

// fotosGuardadas agrupa las URLs publicas de las fotos que acompañan a una
// invitacion, para no arrastrar tres retornos por el handler
type fotosGuardadas struct {
	documento string
	rostro    string
	placa     string
}

// guardarFotos persiste las fotos opcionales del invitado. Devuelve un mensaje
// de error de cliente (400) cuando el formato no es valido, o un error normal
// cuando la falla es del servidor.
func (h *Handler) guardarFotos(c *gin.Context, req UsarInvitacionRequest) (fotosGuardadas, string, error) {
	var out fotosGuardadas

	campos := []struct {
		nombre  string
		archivo *multipart.FileHeader
		destino *string
	}{
		{"foto_documento", req.FotoDocumento, &out.documento},
		{"foto_rostro", req.FotoRostro, &out.rostro},
		{"foto_placa", req.FotoPlaca, &out.placa},
	}

	for _, campo := range campos {
		if campo.archivo == nil {
			continue
		}
		url, err := visitas.GuardarFotoVisitante(c, campo.archivo, h.uploadsDir)
		if err != nil {
			if errors.Is(err, visitas.ErrFormatoFotoInvalido) {
				return out, campo.nombre + ": " + err.Error(), nil
			}
			return out, "", err
		}
		*campo.destino = url
	}

	return out, "", nil
}
