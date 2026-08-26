import 'package:flutter/widgets.dart';

/// Permite a una vista enterarse de cuándo queda tapada por otra ruta y cuándo
/// vuelve a quedar visible.
///
/// El escáner de QR lo necesita porque es la pantalla de inicio y las demás se
/// abren *encima* de ella con `push`: sigue montada y reteniendo la cámara. El
/// kiosko tiene una sola, y el flujo de registro la necesita para el INE y el
/// rostro.
///
/// Hay que registrarlo en `MaterialApp.navigatorObservers`.
final RouteObserver<ModalRoute<void>> observadorDeRutas =
    RouteObserver<ModalRoute<void>>();

/// Navegador raíz de la app.
///
/// Para navegar desde callbacks que sobreviven a la ruta donde nacieron.
/// Capturar un `BuildContext` en un closure de larga vida es una trampa: si esa
/// ruta se reemplaza, el contexto queda desactivado y cualquier
/// `Navigator.of(context)` revienta con *"Looking up a deactivated widget's
/// ancestor is unsafe"* — silenciosamente, porque el error ocurre dentro de un
/// manejador de gestos y no rompe el build: el botón simplemente deja de hacer
/// nada. Este `GlobalKey` no depende de ningún contexto.
final GlobalKey<NavigatorState> navegadorKigo = GlobalKey<NavigatorState>();
