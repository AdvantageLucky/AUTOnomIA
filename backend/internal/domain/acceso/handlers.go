package acceso

import (
	"crypto/rand"
	"encoding/base32"
	"net/http"
	"strconv"

	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

type Handler struct {
	repo *Repository
}

func NewHandler(repo *Repository) *Handler {
	return &Handler{repo: repo}
}

// generateClaveKiosko genera una credencial aleatoria de alta entropia para un kiosko
// usamos el alfabeto base32 estandar (A-Z, 2-7) que no tiene caracteres ambiguos (0/O, 1/I/L)
func generateClaveKiosko() (string, error) {
	b := make([]byte, 10)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return base32.StdEncoding.WithPadding(base32.NoPadding).EncodeToString(b), nil
}

// toAccesoResponse mapea un Acceso a su DTO de respuesta. ClaveKiosko no se incluye aqui: solo
// viaja en texto plano en la respuesta del handler RegisterAccess, una sola vez
func toAccesoResponse(a *Acceso) AccesoResponse {
	return AccesoResponse{
		ID:        a.ID,
		Nombre:    a.Nombre,
		Ubicacion: a.Ubicacion,
		AdminID:   a.AdminID,
	}
}

// RegisterAccess crea un nuevo Acceso del Admin, generando su clave de kiosko
// Request: AccesoRequest
// Response: AccesoResponse (con clave_kiosko en texto plano, solo en esta respuesta)
//
// @Summary Crear acceso
// @Description Registra un nuevo acceso para el admin y genera su clave de kiosko (se devuelve en texto plano una sola vez, aqui)
// @Tags accesos
// @Accept json
// @Produce json
// @Param acceso body AccesoRequest true "Datos del acceso"
// @Success 201 {object} AccesoResponse
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /accesos [post]
func (h *Handler) RegisterAccess(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	var req AccesoRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// generamos la clave kiosko aleatoria
	claveKiosko, err := generateClaveKiosko()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// hasheamos con salt la clave
	hash, err := bcrypt.GenerateFromPassword([]byte(claveKiosko), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	a := &Acceso{
		Nombre:      req.Nombre,
		Ubicacion:   req.Ubicacion,
		ClaveKiosko: string(hash),
		AdminID:     adminID,
	}

	if err := h.repo.Create(a); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	res := toAccesoResponse(a)
	res.ClaveKiosko = claveKiosko

	c.JSON(http.StatusCreated, res)
}

// GetAccessByID busca un acceso por su ID
// Request: id uint (URL Param)
// Response: AccesoReponse
//
// @Summary Obtener acceso por ID
// @Description Busca un acceso del admin autenticado por su ID
// @Tags accesos
// @Produce json
// @Param id path int true "ID del acceso"
// @Success 200 {object} AccesoResponse
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /accesos/{id} [get]
func (h *Handler) GetAccessByID(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	a, err := h.repo.FindByIDAndAdminID(uint(id), adminID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "acceso no encontrado"})
		return
	}

	c.JSON(http.StatusOK, toAccesoResponse(a))
}

// GetAllAccess retorna todos los Accesos del usuario
// Request:
// Response: []AccesoResponse
//
// @Summary Listar accesos
// @Description Devuelve todos los accesos del admin autenticado
// @Tags accesos
// @Produce json
// @Success 200 {array} AccesoResponse
// @Failure 500 {object} map[string]string
// @Router /accesos [get]
func (h *Handler) GetAllAccess(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	accesos, err := h.repo.FindAllByAdminID(adminID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	res := make([]AccesoResponse, 0, len(accesos))
	for i := range accesos {
		res = append(res, toAccesoResponse(&accesos[i]))
	}

	c.JSON(http.StatusOK, res)
}

// PatchAccess modifica el nombre o ubicacion de un acceso (la clave de kiosko no se toca aqui)
// Request: id uint (URL Param) y AccesoRequest
// Response: AccesoResponse
//
// @Summary Modificar acceso
// @Description Modifica el nombre o ubicacion de un acceso del admin autenticado
// @Tags accesos
// @Accept json
// @Produce json
// @Param id path int true "ID del acceso"
// @Param acceso body AccesoRequest true "Datos a modificar"
// @Success 200 {object} AccesoResponse
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /accesos/{id} [patch]
func (h *Handler) PatchAccess(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	var req AccesoRequest
	if err = c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// cargamos el acceso existente para conservar su ClaveKiosko: Update hace un Save() de
	// fila completa, y AccesoRequest ya no trae clave_kiosko (la genera el servidor una sola vez)
	a, err := h.repo.FindByIDAndAdminID(uint(id), adminID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "acceso no encontrado"})
		return
	}

	a.Nombre = req.Nombre
	a.Ubicacion = req.Ubicacion

	if err := h.repo.Update(a, adminID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, toAccesoResponse(a))
}

// DeleteAccess elimina un acceso
// Request: id uint (URL Param)
// Response: ok msg
//
// @Summary Eliminar acceso
// @Description Elimina un acceso del admin autenticado
// @Tags accesos
// @Produce json
// @Param id path int true "ID del acceso"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /accesos/{id} [delete]
func (h *Handler) DeleteAccess(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	if err := h.repo.Delete(uint(id), adminID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "acceso eliminado correctamente"})
}
