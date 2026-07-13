# ADR-0007: Consentimiento de uso de cámara mediante dialog bloqueante

**Estado:** Aceptado
**Fecha:** 2026-06-20
**Autores:** Ivan Ramses y Alberto Luna

## Contexto

La aplicación accede a la cámara del dispositivo para capturar datos
biométricos (imagen de INE, foto de rostro). Las regulaciones de
privacidad y las buenas prácticas requieren informar al usuario antes
de activar la cámara. El permiso de Android de cámara ya se solicita
al instalar la app, pero no informa al usuario del propósito específico
en cada uso dentro del flujo.

## Decisión

Mostramos un AlertDialog con barrierDismissible: false antes de
inicializar el CameraController en cada pantalla de cámara (INE y
rostro). La cámara no se inicializa hasta que el usuario presiona
"Aceptar". Si presiona "Regresar", se ejecuta Navigator.pop() sin
haber activado el hardware de la cámara.

La lógica se extrae a una función reutilizable mostrarConsentimientoCamara()
en consent_dialog.dart para evitar duplicación.

## Consecuencias

Positivas:
- El hardware de la cámara nunca se activa sin acción explícita del
  usuario.
- El diálogo aparece en el momento preciso en que se va a usar la
  cámara, con contexto claro para el usuario.
- La función centralizada garantiza que ambas pantallas muestren el
  mismo texto y comportamiento.

Negativas / Trade-offs:
- Añade un tap adicional en cada uso de la cámara, lo que puede
  percibirse como fricción en un kiosco de alto volumen.
- No persiste la decisión del usuario: si regresa y vuelve a entrar
  a la misma pantalla, el diálogo aparece de nuevo.