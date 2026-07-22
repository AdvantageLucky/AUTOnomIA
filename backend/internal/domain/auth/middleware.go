package auth

import (
	"net/http"
	"strings"

	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
)

// RequireAdmin valida el JWT del header "Authorization: Bearer <token>" y mete el admin_id
// y admin_rol en el contexto de gin
func RequireAdmin(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := bearerToken(c)
		if token == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "token requerido"})
			return
		}

		adminID, rol, err := ParseAdminToken(token, secret)
		if err != nil {
			c.AbortWithStatusJSON(
				http.StatusUnauthorized,
				gin.H{"error": "token invalido o expirado"},
			)
			return
		}

		c.Set(ctxkeys.AdminID, adminID)
		c.Set(ctxkeys.AdminRol, rol)
		c.Next()
	}
}

// RequireAdminRole verifica que el rol del admin autenticado esté en la lista permitida.
// Debe usarse después de RequireAdmin en la cadena de middlewares.
func RequireAdminRole(roles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		rol, _ := c.Get(ctxkeys.AdminRol)
		for _, r := range roles {
			if rol == r {
				c.Next()
				return
			}
		}
		c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "permisos insuficientes"})
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
