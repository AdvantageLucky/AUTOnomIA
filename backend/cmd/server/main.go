package main

import (
	"kigo-autonomia-backend/configs"
	"kigo-autonomia-backend/internal/platform/database"
	"kigo-autonomia-backend/internal/router"
	"log"

	_ "kigo-autonomia-backend/docs"
)

// @title AUTOnomIA API
// @version 1.0
// @description Backend del proyecto AUTOnomIA para FEPRO 2026 BUAP. Gestiona el registro y control de visitantes/accesos en condominios.
// @BasePath /api/v1
func main() {
	// cargamos .env
	cfg, err := configs.Load()
	if err != nil {
		log.Fatalf("Error cargando configuracion: %v", err)
	}

	// corremos migraciones contenidas en migrations/
	if err = database.RunMigrations(cfg.DSN(), "migrations"); err != nil {
		log.Fatalf("Error ejecutando migraciones: %v", err)
	}

	// conectamos a db
	database, err := database.Connect(cfg.DSN())
	if err != nil {
		log.Fatalf("Error conectando a la db: %v", err)
	}

	// iniciamos apps
	r := router.Setup(database, cfg)

	// iniciamos server
	log.Printf("Servidor iniciando en :%s", cfg.ServerPort)
	if err := r.Run(":" + cfg.ServerPort); err != nil {
		log.Fatalf("Error iniciando servidor: %v", err)
	}
}
