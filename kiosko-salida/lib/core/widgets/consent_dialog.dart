import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kigo_salida/core/theme/kigo_design.dart';

const int _segundosParaAceptarAuto = 6;

/// Diálogo de consentimiento antes de activar la cámara -- mismo criterio
/// de privacidad que kiosko/lib/features/registro/views/widgets/consent_dialog.dart,
/// con texto propio (sin depender del sistema de l10n del kiosko).
Future<bool> mostrarConsentimientoCamara(BuildContext context) async {
  final bool? aceptado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      final anchoDialogo = math.min(MediaQuery.of(context).size.width * 0.9, 640.0);
      int segundosRestantes = _segundosParaAceptarAuto;
      Timer? timer;
      bool timerDetenido = false;

      return StatefulBuilder(
        builder: (context, setState) {
          if (!timerDetenido) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (!context.mounted) {
                t.cancel();
                return;
              }
              if (segundosRestantes <= 1) {
                t.cancel();
                Navigator.of(context).pop(true);
                return;
              }
              setState(() => segundosRestantes--);
            });
          }

          void detenerTimer() {
            timerDetenido = true;
            timer?.cancel();
          }

          return AlertDialog(
            backgroundColor: context.kSurfaceCard,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 14),
            contentPadding: const EdgeInsets.fromLTRB(28, 0, 28, 22),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            title: Row(
              children: [
                const Icon(Icons.privacy_tip_outlined, color: KigoDesign.brand, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Antes de continuar',
                    style: TextStyle(color: context.kTextPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: anchoDialogo,
              child: Text(
                'Vamos a tomar una foto de tu rostro para registrar tu salida. '
                'La foto se guarda como evidencia de la bitácora de este centro habitacional, '
                'nunca sale de nuestros servidores ni se comparte con terceros.',
                style: TextStyle(color: context.kTextSecondary, fontSize: 21, height: 1.5),
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 24,
                runSpacing: 12,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            detenerTimer();
                            Navigator.pop(context, true);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                            minimumSize: const Size(150, 64),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Aceptar',
                            style: TextStyle(color: KigoDesign.brand, fontWeight: FontWeight.bold, fontSize: 22),
                          ),
                        ),
                        if (!timerDetenido) ...[
                          const SizedBox(width: 8),
                          Text(
                            '($segundosRestantes)',
                            style: const TextStyle(color: KigoDesign.brand, fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ],
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      detenerTimer();
                      Navigator.pop(context, false);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      minimumSize: const Size(150, 64),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Regresar',
                      style: TextStyle(color: context.kTextSecondary, fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );

  return aceptado ?? false;
}
