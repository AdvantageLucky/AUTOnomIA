package persona

import "github.com/gin-gonic/gin"

// EstadoKigoMiniApp responde a la mini-app del marketplace de Kigo
// Parkimovil (ver docs/integracion-kigo-marketplace-y-face-enrollment.md).
// kigo.auth.init() del lado del cliente solo entrega un userId -- nunca
// teléfono ni nombre -- así que esta ruta es deliberadamente pública y
// deliberadamente pobre en datos: contesta nada más si ese userId ya está
// vinculado a una Persona, nunca el registro completo. Vincular
// kigo_user_id a una Persona pasa por otro camino (completar el alta en la
// app AUTOnomIA), esta ruta no lo hace.
func (h *Handler) EstadoKigoMiniApp(c *gin.Context) {
	kigoUserID := c.Query("kigo_user_id")
	if kigoUserID == "" {
		c.JSON(400, gin.H{"error": "kigo_user_id es requerido"})
		return
	}

	vinculado, err := h.repo.ExisteVinculoKigoUserID(kigoUserID)
	if err != nil {
		c.JSON(500, gin.H{"error": "error interno"})
		return
	}

	c.JSON(200, gin.H{"vinculado": vinculado})
}
