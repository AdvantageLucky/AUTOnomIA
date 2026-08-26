import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'pantalla_error.dart';

/// Sonda de diagnóstico superpuesta a toda la app.
///
/// Existe para responder una sola pregunta cuando el kiosko "se congela":
/// ¿está muerto el isolate de Dart, o solo no llegan los toques?
///
/// El contador avanza en cada cuadro que Flutter logra producir. Durante un
/// congelamiento:
///
/// * **Contador detenido** → el isolate está bloqueado (bucle infinito o
///   deadlock). La textura de la cámara sigue viva porque la compone la
///   plataforma, no Dart.
/// * **Contador avanzando** → Dart está sano y el problema es que los toques
///   no llegan a los botones: típicamente una barrera modal invisible que se
///   quedó en la pila de rutas.
///
/// Va dentro de un `IgnorePointer`, así que no puede robar toques ni ser la
/// causa de lo que investiga. Quitar cuando el bug esté cerrado.
class SondaDiagnostico extends StatefulWidget {
  const SondaDiagnostico({super.key});

  @override
  State<SondaDiagnostico> createState() => _SondaDiagnosticoState();
}

class _SondaDiagnosticoState extends State<SondaDiagnostico>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<int> _cuadros = ValueNotifier(0);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _cuadros.value++)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _cuadros.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<int>(
                valueListenable: _cuadros,
                builder: (context, cuadros, _) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: Colors.black.withValues(alpha: 0.6),
                  child: Text(
                    'F$cuadros',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder<String?>(
                valueListenable: ultimoError,
                builder: (context, error, _) {
                  if (error == null) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(maxWidth: 320),
                    color: const Color(0xFFFF4D6A).withValues(alpha: 0.9),
                    child: Text(
                      error,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
