/*
Package configs
Configuracion del backend apartir de archivo .env
En el archivo .env se obtiene informacion relacionada a la conexion con la base de datos postgreSQL
y el puerto para correr el servidor.

function Load() -> (*Config, error)
Se encarga de cargar variables de entorno y retorna un puntero a la estructura Config que contiene las variables
necesarias para el servidor. Para sacar las variables de entorno usamos getEnv que busca la variable "key" y retorna el valor
que tenga dicha variable. Sino encuentra nada retorna "fallback".

Usamos godotenv para poder cargar el archivo .env que ya supone os.Getenv como cargado
*/
package configs

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	DBHost                  string
	DBPort                  string
	DBUser                  string
	DBPassword              string
	DBName                  string
	ServerPort              string
	JWTSecret               string
	QRMasterSecret          string
	UploadsDir              string
	LLMUrl                  string
	PublicURL               string
	FirebaseCredentialsPath string
	GoogleClientID          string
	SMTPHost                string
	SMTPPort                string
	SMTPUser                string
	SMTPPassword            string
}

func Load() (*Config, error) {
	_ = godotenv.Load()
	cfg := &Config{
		DBHost:                  getEnv("DB_HOST", "localhost"),
		DBPort:                  getEnv("DB_PORT", "5432"),
		DBUser:                  getEnv("DB_USER", "kigo"),
		DBPassword:              getEnv("DB_PASSWORD", ""),
		DBName:                  getEnv("DB_NAME", "kigo_db"),
		ServerPort:              getEnv("SERVER_PORT", "8080"),
		JWTSecret:               getEnv("JWT_SECRET", "dev-secret-change-me"),
		QRMasterSecret:          getEnv("QR_MASTER_SECRET", "dev-qr-secret-change-me"),
		UploadsDir:              getEnv("UPLOADS_DIR", "./web/uploads/visitantes"),
		LLMUrl:                  getEnv("LLM_URL", "http://localhost:8081"),
		PublicURL:               getEnv("PUBLIC_URL", "http://localhost:8080"),
		FirebaseCredentialsPath: getEnv("FIREBASE_CREDENTIALS_PATH", ""),
		GoogleClientID:          getEnv("GOOGLE_CLIENT_ID", ""),
		SMTPHost:                getEnv("SMTP_HOST", "smtp.gmail.com"),
		SMTPPort:                getEnv("SMTP_PORT", "587"),
		SMTPUser:                getEnv("SMTP_USER", ""),
		SMTPPassword:            getEnv("SMTP_PASSWORD", ""),
	}

	return cfg, nil
}

func (c *Config) DSN() string {
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s?sslmode=disable&timezone=America/Mexico_City",
		c.DBUser,
		c.DBPassword,
		c.DBHost,
		c.DBPort,
		c.DBName,
	)
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
