# ADR-0003: Identidad de Persona por teléfono + OTP, con membresías por centro

**Estado:** Aceptado
**Fecha:** 2026-08-17
**Relacionado:** backend ADR-0031 (Persona + Membresia reemplazan a Residente)

## Contexto

La versión original de esta app (entonces "kigo_user") modelaba al usuario como `Residente`: alta
con nombre/teléfono/PIN/rostro dentro de una sola instalación (código de instalación + casa +
contraseña/PIN), documentada en el `README.md` original. Esa identidad no sobrevivía a que la misma
persona tuviera relación con más de un centro administrado por AUTOnomIA — cada instalación exigía un
alta y una captura de rostro independientes. El backend resolvió esto introduciendo `Persona` (global,
ancla en teléfono) y `Membresia` (la relación con cada centro) — ver backend ADR-0031. Esta app tuvo
que rediseñar por completo su modelo de sesión y su wizard de alta para reflejar ese cambio.

## Decisión

1. **El login es por teléfono, verificado con un código OTP** — no usuario/contraseña ni PIN de
   entrada directo. `AuthViewModel.solicitarOtp` / `.verificarOtp` llaman
   `POST /personas/registro/{solicitar-otp,verificar-otp}`; el JWT resultante identifica una
   `Persona`, no una membresía concreta.

2. **El wizard de onboarding tiene 4 pasos secuenciales, cada uno condicionado al anterior:**
   teléfono → OTP → identidad (INE + rostro, solo si `perfilCompleto` es `false`) → unirse a un
   centro. Completar identidad es un evento de la `Persona` (una sola vez en la vida de la cuenta);
   unirse a un centro crea una `Membresia` nueva y puede repetirse sin volver a pasar por identidad.

3. **El PIN ya no lo elige la persona.** `unirseCentro` no manda ningún PIN — el backend lo genera y
   lo devuelve dentro de la `Membresia`, para que la pantalla "Mi QR" pueda mostrarlo. Este es un
   cambio deliberado frente al README original ("define un PIN de 4-6 dígitos"): el PIN sigue
   existiendo para el login rápido en el kiosko, pero ya no es un dato que el usuario aporte.

4. **Multi-membresía es de primera clase en el cliente**, no un caso raro: `AuthViewModel` expone
   `membresias`, `membresiasActivas` y un `centroActivo` seleccionable (ver ADR-0007 de esta misma
   carpeta) — la sesión de una Persona puede tener cero, una o varias membresías simultáneamente, en
   distintos estados (`pendiente`, `rechazado`, `activo`).

## Consecuencias

- Una persona con membresías en dos centros solo pasa por el wizard de identidad una vez; unirse al
  segundo centro es solo el último paso del wizard, sin repetir teléfono, OTP, INE ni rostro.
- El README de la app (`kigo-app/README.md`) describe todavía el modelo `Residente` anterior
  (alta por código de instalación + PIN elegido por el residente) — quedó desactualizado por este
  rediseño y debe corregirse aparte de este ADR.
- El estado de sesión ya no es binario (autenticado/no autenticado): existe un estado intermedio
  real donde la `Persona` tiene sesión pero **cero membresías activas** (`MembresiaEstado.ninguna`,
  `.pendiente`, `.rechazada`), que las vistas post-login deben manejar explícitamente en vez de
  asumir que login implica acceso a un centro.
- `completarIdentidad` es una operación que no se puede repetir con datos distintos desde esta app —
  no hay pantalla para "recapturar" INE o rostro si la persona se equivocó, más allá de reintentar
  antes de que el POST tenga éxito.
