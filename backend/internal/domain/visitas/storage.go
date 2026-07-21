/*
Package visitas

Logica de almacenamiento de fotos de visitantes
Valida extension y Content-Type de la foto, genera un nombre de archivo aleatorio (hex de 16 bytes)
y lo guarda en el directorio configurado en UPLOADS_DIR

La URL publica devuelta asume que el directorio esta servido bajo /uploads/visitantes/
*/
package visitas

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"mime/multipart"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
)

var errFormatoFotoInvalido = errors.New("formato de foto no soportado (usa jpg o png)")

var fotoContentTypesPermitidos = map[string]bool{
	"image/jpeg": true,
	"image/png":  true,
}

var fotoExtensionesPermitidas = map[string]bool{
	".jpg":  true,
	".jpeg": true,
	".png":  true,
}

func guardarFotoVisitante(c *gin.Context, foto *multipart.FileHeader, dir string) (string, error) {
	ext := strings.ToLower(filepath.Ext(foto.Filename))
	if !fotoExtensionesPermitidas[ext] ||
		!fotoContentTypesPermitidos[foto.Header.Get("Content-Type")] {
		return "", errFormatoFotoInvalido
	}

	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	nombreArchivo := hex.EncodeToString(b) + ext

	if err := c.SaveUploadedFile(foto, filepath.Join(dir, nombreArchivo)); err != nil {
		return "", err
	}

	scheme := "http"
	if c.Request.TLS != nil {
		scheme = "https"
	}
	return fmt.Sprintf("%s://%s/uploads/visitantes/%s", scheme, c.Request.Host, nombreArchivo), nil
}
