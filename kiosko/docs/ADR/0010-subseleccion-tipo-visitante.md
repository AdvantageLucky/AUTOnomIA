# ADR-0010: Sub-selección de tipo de visitante antes del flujo de acceso

**Estado:** Aceptado
**Fecha:** 2026-07-10
**Autores:** Alberto Luna

## Contexto

Los visitantes externos pueden llegar al kiosco en dos situaciones
distintas: con una invitación previa (código QR enviado por el anfitrión)
o sin invitación (registro en el momento con INE). Meter ambos casos en
un solo flujo generaría pasos innecesarios para quienes ya tienen
invitación.

## Decisión

Al tocar "Visitante" en WelcomeView se navega a VisitorTypeView, una
pantalla intermedia con dos botones: "Tengo invitación" y "Soy visitante".
Cada botón inicia su propio flujo:
- "Tengo invitación" → QrScannerView (lectura de QR)
- "Soy visitante" → TouchRegisterView (registro con INE y biometría)

## Consecuencias

Positivas:
- Visitantes con invitación acceden en un solo scan sin pasar por el
  proceso de registro con INE.
- El flujo de registro con INE queda intacto para visitantes sin cita.

Negativas / Trade-offs:
- Los visitantes sin invitación tienen un paso extra (la pantalla
  intermedia) comparado con el flujo anterior.
- Agrega una vista y un ViewModel adicionales al feature de welcome.