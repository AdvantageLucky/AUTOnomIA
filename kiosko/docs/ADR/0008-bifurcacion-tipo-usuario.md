# ADR-0008: Bifurcación del flujo de entrada según tipo de usuario

**Estado:** Aceptado
**Fecha:** 2026-07-10
**Autores:** Alberto

## Contexto

La pantalla de bienvenida original tenía un único botón de huella dactilar
que iniciaba el mismo flujo para todos los usuarios, lo que obstaculisaba un 
registro rápido. El kiosco necesita atender dos perfiles distintos: residentes 
del edificio y visitantes externos, cada uno con un proceso de acceso diferente.

## Decisión

Reemplazamos el botón único por dos botones cuadrados con bordes redondeados
en la WelcomeView: "Residente" (icono de casa) y "Visitante" (icono de
persona). Cada botón inicia un flujo de navegación independiente.
Las opciones se modelan en WelcomeViewModel usando RegisterOptionModel,
manteniendo la misma estructura que el resto de la feature.

## Consecuencias

Positivas:
- El kiosco puede servir a dos tipos de usuarios con experiencias
  diferenciadas desde el primer tap.
- La lógica de navegación por tipo está centralizada en WelcomeView,
  fácil de extender con más perfiles en el futuro.

Negativas / Trade-offs:
- El usuario debe tomar una decisión adicional antes de iniciar el proceso,
  lo que añade un paso en comparación al flujo anterior.