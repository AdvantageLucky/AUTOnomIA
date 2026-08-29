package asistente

import (
	"context"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"

	"kigo-autonomia-backend/internal/domain/destinos"
	"kigo-autonomia-backend/internal/domain/kiosko"
	"kigo-autonomia-backend/internal/platform/ctxkeys"
	"kigo-autonomia-backend/internal/platform/llmclient"
)

const respuestaFallback = "No puedo responder eso ahora mismo, pero puedes tocar 'Visitante' para empezar tu registro."

type Handler struct {
	kioskoRepo  *kiosko.Repository
	destinoRepo *destinos.Repository
	llmURL      string
}

func NewHandler(kioskoRepo *kiosko.Repository, destinoRepo *destinos.Repository, llmURL string) *Handler {
	return &Handler{kioskoRepo: kioskoRepo, destinoRepo: destinoRepo, llmURL: llmURL}
}

func kioskoIDFromParam(c *gin.Context) (uint, bool) {
	id64, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		return 0, false
	}
	sesionKioskoID := c.MustGet(ctxkeys.KioskoID).(uint)
	if sesionKioskoID != uint(id64) {
		return 0, false
	}
	return uint(id64), true
}

// Preguntar responde una pregunta libre del visitante — nunca dispara
// acciones ni navegación, solo texto para que el kiosko lo lea con TTS.
func (h *Handler) Preguntar(c *gin.Context) {
	kioskoID, ok := kioskoIDFromParam(c)
	if !ok {
		c.JSON(http.StatusForbidden, gin.H{"error": "la sesion no corresponde a este kiosko"})
		return
	}

	var req struct {
		Pregunta string `json:"pregunta"`
	}
	if err := c.ShouldBindJSON(&req); err != nil || req.Pregunta == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "pregunta requerida"})
		return
	}

	cfg, _ := h.kioskoRepo.FindConfigByKioskoID(kioskoID)

	ctx, cancel := context.WithTimeout(c.Request.Context(), 20*time.Second)
	defer cancel()

	respuesta, err := llmclient.Completar(ctx, h.llmURL, systemPromptPreguntar, construirPromptPreguntar(req.Pregunta, cfg))
	if err != nil || respuesta == "" {
		respuesta = respuestaFallback
	}

	c.JSON(http.StatusOK, gin.H{"respuesta": respuesta})
}
