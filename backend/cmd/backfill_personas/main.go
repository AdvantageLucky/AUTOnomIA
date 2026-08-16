package main

import (
	"flag"
	"fmt"
	"log"

	"kigo-autonomia-backend/configs"
	"kigo-autonomia-backend/internal/domain/persona"
	"kigo-autonomia-backend/internal/domain/residente"
	"kigo-autonomia-backend/internal/platform/database"

	"gorm.io/gorm"
)

func main() {
	commit := flag.Bool("commit", false, "si no se pasa, solo reporta qué haría sin escribir nada (dry-run)")
	flag.Parse()

	cfg, err := configs.Load()
	if err != nil {
		log.Fatalf("cargando configuración: %v", err)
	}

	db, err := database.Connect(cfg.DSN())
	if err != nil {
		log.Fatalf("conectando a la base de datos: %v", err)
	}

	var residentes []residente.Residente
	if err := db.Find(&residentes).Error; err != nil {
		log.Fatalf("leyendo residentes: %v", err)
	}

	resultado := persona.ConstruirBackfill(residentes)

	totalMembresias := 0
	for _, g := range resultado.Grupos {
		totalMembresias += len(g.Membresias)
	}

	fmt.Printf("Residentes leídos: %d\n", len(residentes))
	fmt.Printf("Personas a crear: %d\n", len(resultado.Grupos))
	fmt.Printf("Membresias a crear: %d\n", totalMembresias)
	fmt.Printf("Residentes omitidos (sin teléfono): %d\n", len(resultado.Omitidos))
	for _, r := range resultado.Omitidos {
		fmt.Printf("  - residente #%d (%s %s), tenant %d, casa %q\n",
			r.ID, r.Nombre, r.ApellidoPaterno, r.TenantID, r.CasaDestino)
	}

	if !*commit {
		fmt.Println("\nModo simulación (dry-run) — no se escribió nada. Corre con --commit para aplicar los cambios.")
		return
	}

	err = db.Transaction(func(tx *gorm.DB) error {
		txPersonaRepo := persona.NewRepository(tx)
		txMembresiaRepo := residente.NewMembresiaRepository(tx)

		for gi := range resultado.Grupos {
			g := &resultado.Grupos[gi]

			if existente, err := txPersonaRepo.FindByTelefono(g.Persona.Telefono); err == nil {
				g.Persona = *existente
			} else if err := txPersonaRepo.Create(&g.Persona); err != nil {
				return fmt.Errorf("creando persona %q: %w", g.Persona.Telefono, err)
			}

			for mi := range g.Membresias {
				g.Membresias[mi].PersonaID = g.Persona.ID
				if _, err := txMembresiaRepo.FindByPersonaAndTenant(g.Persona.ID, g.Membresias[mi].TenantID); err == nil {
					continue // ya migrada en una corrida anterior
				}
				if err := txMembresiaRepo.Create(&g.Membresias[mi]); err != nil {
					return fmt.Errorf("creando membresia (persona %q, tenant %d, casa %q): %w",
						g.Persona.Telefono, g.Membresias[mi].TenantID, g.Membresias[mi].CasaDestino, err)
				}
			}
		}
		return nil
	})
	if err != nil {
		log.Fatalf("backfill falló, nada se escribió (transacción revertida): %v", err)
	}

	fmt.Println("\nBackfill completo.")
}
