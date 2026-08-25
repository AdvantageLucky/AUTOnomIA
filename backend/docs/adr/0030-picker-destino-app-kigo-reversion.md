# ADR-0030: La app Kigo sí obtiene un picker de destino — se revierte el punto 5 de ADR-0027

**Estado:** Aceptado
**Fecha:** 2026-08-25
**Reemplaza parcialmente:** ADR-0027 (punto 5)

## Contexto

ADR-0027 decidió deliberadamente que la app Kigo NO tendría un picker de
destino al unirse a un centro — el riesgo de privacidad de exponer el
directorio completo de un centro habitacional a través de un código público
se consideró peor que la fricción de un campo de texto libre validado en el
backend (`FindCanonicoPorTenant`, normalizado sin distinguir mayúsculas ni
espacios).

En la práctica, ese texto libre resultó **inutilizable**: nadie lograba
escribir la casa exactamente como el admin la había dado de alta (el error
de "no encontramos esa casa" era la norma, no la excepción), al punto de
bloquear el flujo de unirse a un centro por completo.

## Decisión

**`UnirseCentro` gana un picker progresivo (calle → tipo → número), igual al
que ya usa el kiosko — con una mitigación que el kiosko no necesita.**

1. Nuevo endpoint `GET /personas/me/centros/:codigo/destinos` — a diferencia
   de `GET /personas/me/destinos` (que exige membresía activa, inútil aquí
   porque el punto es *crear* la membresía), este resuelve el tenant por
   código público y no exige membresía previa.
2. **Requiere Persona autenticada**, no es anónimo — a diferencia del
   endpoint del kiosko (que corre en un dispositivo físico de confianza) o
   de un endpoint público sin autenticar. Quien lo llama ya pasó por
   teléfono+correo verificado por OTP; no es "cualquiera con el código", es
   cualquiera con el código *y* una cuenta de Kigo real. Se consideró
   suficiente mitigación: el directorio expuesto es la estructura del
   centro (calles, tipos, números), no datos de residentes.
3. `StepUnirseCentro` pasa de un formulario plano a un mini-wizard: código →
   calle → tipo (si la calle tiene más de uno) → número → PIN — mismo patrón
   de sub-pasos que `CasaDestinoView` del kiosko, reutilizando el mismo
   contrato de datos (`calle`/`tipo`/`numero`/`nombre` por destino).

## Consecuencias

- El trade-off de privacidad de ADR-0027 no desaparece — se acota: ahora
  hace falta una cuenta de Persona real (teléfono + correo verificados) para
  ver el directorio de un centro, no solo el código público. Sigue siendo
  más expuesto que el kiosko (dispositivo físico) pero bastante menos que un
  endpoint anónimo.
- La validación normalizada de `UnirseCentro` (`FindCanonicoPorTenant`) se
  queda como está — con el picker, la persona ya no escribe nada a mano, así
  que en la práctica siempre coincide exacto. El código de validación no se
  quita: sigue siendo la defensa correcta si algún día se reintroduce un
  campo de texto libre en algún otro punto de entrada.
- Si el volumen de un centro es muy grande y la lista de calles se vuelve
  larga, el mismo problema de "lista plana no escala" que motivó ADR-0027
  del lado del kiosko aplica aquí también — no se resolvió aparte porque el
  picker ya agrupa por calle primero, igual que el kiosko.
