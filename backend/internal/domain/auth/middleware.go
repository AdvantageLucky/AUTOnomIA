package auth

import (
	"net/http"
	"strings"

	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
)

// RequireAdmin valida el JWT del header "Authorization: Bearer <token>" y mete el admin_id,
// admin_rol y tenant_id en el contexto de gin
func RequireAdmin(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := bearerToken(c)
		if token == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "token requerido"})
			return
		}

		// Extraemos también el tenantID del JWT
		adminID, rol, tenantID, err := ParseAdminToken(token, secret)
		if err != nil {
			c.AbortWithStatusJSON(
				http.StatusUnauthorized,
				gin.H{"error": "token invalido o expirado"},
			)
			return
		}

		c.Set(ctxkeys.AdminID, adminID)
		c.Set(ctxkeys.AdminRol, rol)
		c.Set(ctxkeys.TenantID, tenantID) // <-- NUEVO: Inyección del TenantID
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

// RequireKiosko valida la sesion persistida del kiosko y mete el kiosko_id y tenant_id en el contexto
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
		c.Set(ctxkeys.TenantID, sesion.TenantID) // <-- NUEVO: Inyección del TenantID de la BD
		c.Next()
	}
}

// RequireResidente valida el JWT del residente y mete el residente_id y tenant_id en el contexto
func RequireResidente(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := bearerToken(c)
		if token == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "token requerido"})
			return
		}

		// Extraemos también el tenantID del JWT
		residenteID, tenantID, err := ParseResidenteToken(token, secret)
		if err != nil {
			c.AbortWithStatusJSON(
				http.StatusUnauthorized,
				gin.H{"error": "token invalido o expirado"},
			)
			return
		}

		c.Set(ctxkeys.ResidenteID, residenteID)
		c.Set(ctxkeys.TenantID, tenantID) // <-- NUEVO: Inyección del TenantID
		c.Next()
	}
}

func bearerToken(c *gin.Context) string {
	const prefix = "Bearer "
	header := c.GetHeader("Authorization")
	if strings.HasPrefix(header, prefix) {
		return strings.TrimPrefix(header, prefix)
	}
	// EventSource no puede enviar headers; acepta ?token= solo para SSE
	if q := c.Query("token"); q != "" {
		return q
	}
	return ""
}
