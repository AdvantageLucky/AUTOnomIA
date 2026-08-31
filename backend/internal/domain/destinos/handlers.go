package destinos

import (
	"net/http"
	"strconv"

	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	repo *Repository
}

func NewHandler(repo *Repository) *Handler {
	return &Handler{repo: repo}
}

func tenantFromCtx(c *gin.Context) (uint, bool) {
	v, exists := c.Get(ctxkeys.TenantID)
	if !exists {
		return 0, false
	}
	id, ok := v.(uint)
	return id, ok && id > 0
}

// ListarDestinosPorAcceso — kiosko: lista todos los destinos del tenant
func (h *Handler) ListarDestinosPorAcceso(c *gin.Context) {
	kioskoIDStr := c.Param("id")
	kioskoID, err := strconv.ParseUint(kioskoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de kiosko invalido"})
		return
	}

	sesionKioskoID := c.MustGet(ctxkeys.KioskoID).(uint)
	if sesionKioskoID != uint(kioskoID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "la sesion no corresponde a este kiosko"})
		return
	}

	tenantID, ok := tenantFromCtx(c)
	if !ok {
		c.JSON(http.StatusForbidden, gin.H{"error": "tenant no resuelto"})
		return
	}

	list, err := h.repo.WithContext(c.Request.Context()).FindByTenantID(tenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]DestinoResponse, 0, len(list))
	for _, d := range list {
		items = append(items, toDestinoResponse(d))
	}
	c.JSON(http.StatusOK, items)
}

// ListarDestinos — admin: lista todos los destinos del tenant
func (h *Handler) ListarDestinos(c *gin.Context) {
	tenantID, ok := tenantFromCtx(c)
	if !ok {
		c.JSON(http.StatusForbidden, gin.H{"error": "tenant no resuelto"})
		return
	}

	list, err := h.repo.WithContext(c.Request.Context()).FindByTenantID(tenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]DestinoResponse, 0, len(list))
	for _, d := range list {
		items = append(items, toDestinoResponse(d))
	}
	c.JSON(http.StatusOK, items)
}

// CrearDestino — admin: crea un destino a nivel del tenant
func (h *Handler) CrearDestino(c *gin.Context) {
	tenantID, ok := tenantFromCtx(c)
	if !ok {
		c.JSON(http.StatusForbidden, gin.H{"error": "tenant no resuelto"})
		return
	}

	var req DestinoAdminRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tipo := TipoDestino(req.Tipo)
	d := &Destino{
		TenantID: tenantID,
		Nombre:   nombreDestino(req.Calle, tipo, req.Numero),
		Calle:    req.Calle,
		Tipo:     tipo,
		Numero:   req.Numero,
		Titular:  req.Titular,
	}

	if err := h.repo.WithContext(c.Request.Context()).Create(d); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, toDestinoResponse(*d))
}

// CrearDestinosLote — admin: da de alta N destinos de una calle y tipo de
// una sola llamada, un número por cada elemento de la lista.
func (h *Handler) CrearDestinosLote(c *gin.Context) {
	tenantID, ok := tenantFromCtx(c)
	if !ok {
		c.JSON(http.StatusForbidden, gin.H{"error": "tenant no resuelto"})
		return
	}

	var req DestinoLoteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// El binding no puede exigir la lista porque hay dos formas validas de
	// mandarla (ver DestinoLoteRequest.items), asi que se valida aqui.
	elementos := req.items()
	if len(elementos) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "manda al menos un destino"})
		return
	}

	nuevos := make([]Destino, 0, len(elementos))
	for _, it := range elementos {
		if it.Numero == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "cada destino necesita un numero o identificador"})
			return
		}
		tipo := TipoDestino(it.Tipo)
		if tipo == "" {
			tipo = TipoDestinoCasa
		}
		nuevos = append(nuevos, Destino{
			TenantID: tenantID,
			Nombre:   nombreDestino(req.Calle, tipo, it.Numero),
			Calle:    req.Calle,
			Tipo:     tipo,
			Numero:   it.Numero,
		})
	}

	if err := h.repo.WithContext(c.Request.Context()).CreateLote(nuevos); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]DestinoResponse, len(nuevos))
	for i, d := range nuevos {
		items[i] = toDestinoResponse(d)
	}
	c.JSON(http.StatusCreated, gin.H{"destinos": items})
}

// EliminarDestino — admin: elimina un destino del tenant
func (h *Handler) EliminarDestino(c *gin.Context) {
	tenantID, ok := tenantFromCtx(c)
	if !ok {
		c.JSON(http.StatusForbidden, gin.H{"error": "tenant no resuelto"})
		return
	}

	destinoIDStr := c.Param("id")
	destinoID, err := strconv.ParseUint(destinoIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de destino invalido"})
		return
	}

	if err := h.repo.WithContext(c.Request.Context()).Delete(uint(destinoID), tenantID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}
