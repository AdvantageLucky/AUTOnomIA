/*
Package visitas

Logica de paginacion compartida entre los handlers de visitas
defaultPageSize y maxPageSize son los limites de pagina aplicados cuando el cliente
no manda page/page_size o manda valores invalidos
*/
package visitas

import (
	"strconv"

	"github.com/gin-gonic/gin"
)

const (
	defaultPageSize = 20
	maxPageSize     = 100
)

func parsePagination(c *gin.Context) (page, pageSize int) {
	page, err := strconv.Atoi(c.Query("page"))
	if err != nil || page < 1 {
		page = 1
	}
	pageSize, err = strconv.Atoi(c.Query("page_size"))
	if err != nil || pageSize < 1 {
		pageSize = defaultPageSize
	}
	if pageSize > maxPageSize {
		pageSize = maxPageSize
	}
	return page, pageSize
}
