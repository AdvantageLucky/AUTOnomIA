# ADR-0001: Patrón ViewModel + ChangeNotifier para manejo de estado

**Estado:** Aceptado
**Fecha:** 2026-05-01
**Autores:** Alberto Luna, Ivan Ramirez y Jesus Mendoza

## Contexto

La aplicación kigo_kiosco necesita coordinar múltiples pasos de un flujo
secuencial (registro por cámara) donde la UI debe reaccionar a cambios de
estado: paso actual, si se está procesando, si ocurrió un error. Se evaluó
usar setState directamente en los widgets o un gestor de estado externo.

## Decisión

Usamos el patrón MVVM con ChangeNotifier nativo de Flutter, sin librerías
externas de estado (no Bloc, no Riverpod). Cada feature expone un ViewModel
que extiende ChangeNotifier. Las vistas se suscriben con addListener /
removeListener o mediante Provider.

## Consecuencias

Positivas:
- Sin dependencias adicionales para el manejo de estado.
- El ViewModel concentra toda la lógica de negocio fuera del widget tree.
- Fácil de testear el ViewModel de forma aislada.

Negativas / Trade-offs:
- addListener / removeListener manual en StatefulWidgets es más verboso
  que un Consumer de Riverpod.
- Para flujos más complejos en el futuro, ChangeNotifier puede volverse
  difícil de mantener comparado con streams o BLoC.