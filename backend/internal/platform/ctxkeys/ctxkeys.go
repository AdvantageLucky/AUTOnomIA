/*
Package ctxkeys

Constantes de llaves usadas con gin.Context.Set/Get para pasar la identidad
autenticada (admin_id via JWT, kiosko_id via sesion de kiosko) de los
middlewares de internal/domain/auth/ a los handlers de cada dominio.

Vive en su propio paquete (sin depender de auth/ ni de ningun dominio) para
evitar un ciclo de imports: auth/ depende de kiosko/ y admin/ para resolver
login, pero kiosko/, admin/ y visitantes/ tambien necesitan leer estas llaves
en sus handlers.
*/
package ctxkeys

const (
	AdminID     = "admin_id"
	AdminRol    = "admin_rol"
	KioskoID    = "kiosko_id"
	ResidenteID = "residente_id"
)
