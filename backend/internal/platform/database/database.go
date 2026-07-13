/*
Package database
Conexion e inicializacion del orm gorm.
Este paquete funciona como el entry point para conectarse con postgreSQL,
connectar orm a la db y ejecutar migraciones pendientes con la ayuda de gorm

function Connect(dsn string) ->(*gorm.DB, error)
Esta funcion se encarga de conectarse a la base de datos dado un
data source name (dsn) con el cual se hace conexion a la base de datos. Dicho DSN
es proveido por el package "config" con el metodo DSN() de la interfaz Config.
Se retorna una struct DB que simboliza la conexion con la base de datos y
que contiene metodos CRUD/ORM para usar en models definidos

function RunMigrations(dsn, migrationsPath string) -> error
Ejecuta cambios detectados en los modelos apartir de archivos de migraciones
en la ruta file://migrationsPath (que en main siempre sera en migrations/)
*/
package database

import (
	"log"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// Connect abre la conexión con PostgreSQL via GORM.
// Los schemas los maneja go-migrate
func Connect(dsn string) (*gorm.DB, error) {
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		return nil, err
	}

	sqlDB, err := db.DB()
	if err != nil {
		return nil, err
	}

	sqlDB.SetMaxOpenConns(25)
	sqlDB.SetMaxIdleConns(5)

	return db, nil
}

// RunMigrations ejecuta las migraciones pendientes desde el directorio indicado.
func RunMigrations(dsn, migrationsPath string) error {
	m, err := migrate.New("file://"+migrationsPath, dsn)
	if err != nil {
		return err
	}

	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		return err
	}

	log.Println("Migraciones aplicadas correctamente")
	return nil
}
