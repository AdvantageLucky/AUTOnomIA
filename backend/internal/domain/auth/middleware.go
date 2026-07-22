package auth

import (
	"net/http"
	"strings"

	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
)

// RequireAdmin valida el JWT del header "Authorization: Bearer <token>" y mete el admin_id
// que contiene en el contexto de gin (ctxkeys.AdminID)
func RequireAdmin(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := bearerToken(c)
		if token == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "token requerido"})
			return
		}

		adminID, err := ParseAdminToken(token, secret)
		if err != nil {
			c.AbortWithStatusJSON(
				http.StatusUnauthorized,
				gin.H{"error": "token invalido o expirado"},
			)
			return
		}

		c.Set(ctxkeys.AdminID, adminID)
		c.Next()
	}
}

// RequireKiosko valida la sesion persistida del kiosko (header "Authorization: Bearer <token>")
// contra sesionRepo y mete el kiosko_id de esa sesion en el contexto de gin (ctxkeys.KioskoID),
// para las rutas de registro/consulta de visitantes anidadas bajo /kioskos/:id/visitas.
func RequireKiosko(sesionRepo *SesionRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := bearerToken(c)
		if token == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "token requerido"})
			return
		}

		sesion, err := sesionRepo.FindActiveByToken(token)
		if err != nil {
			c.AbortWithStatusJSON(
				http.StatusUnauthorized,
				gin.H{"error": "sesion invalida o revocada"},
			)
			return
		}

		c.Set(ctxkeys.KioskoID, sesion.KioskoID)
		c.Next()
	}
}

// RequireResidente valida el JWT del residente y mete el residente_id en el contexto
func RequireResidente(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := bearerToken(c)
		if token == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "token requerido"})
			return
		}

		residenteID, err := ParseResidenteToken(token, secret)
		if err != nil {
			c.AbortWithStatusJSON(
				http.StatusUnauthorized,
				gin.H{"error": "token invalido o expirado"},
			)
			return
		}

		c.Set(ctxkeys.ResidenteID, residenteID)
		c.Next()
	}
}

func bearerToken(c *gin.Context) string {
	const prefix = "Bearer "
	header := c.GetHeader("Authorization")
	if !strings.HasPrefix(header, prefix) {
		return ""
	}
	return strings.TrimPrefix(header, prefix)
}
