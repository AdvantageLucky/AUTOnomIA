/* VENTANA DE CONSENTIMIENTO */

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Segundos antes de aceptar automáticamente el consentimiento.
const int _segundosParaAceptarAuto = 6;

/// Muestra un diálogo de consentimiento de uso de datos antes de activar la cámara.
/// Se acepta automáticamente tras [_segundosParaAceptarAuto] segundos si el
/// usuario no interactúa antes.
/// Retorna `true` si el usuario acepta, `false` si decide regresar.
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
          // Arranca el conteo una sola vez; si se detiene (p. ej. al abrir
          // términos y condiciones), no se vuelve a crear en el siguiente rebuild.
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
            backgroundColor: const Color(0xFF211D1D),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 14),
            contentPadding: const EdgeInsets.fromLTRB(28, 0, 28, 22),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            title: const Row(
              children: [
                Icon(Icons.privacy_tip_outlined, color: Color(0xFFFF542F), size: 36),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Consentimiento de datos',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: anchoDialogo,
              // ↓↓↓ Edita aquí el texto del aviso de consentimiento ↓↓↓
              child: const Text(
                'Estas a punto de confiarnos datos sencibles para acceder a las instalaciones.'
                ' \n\n'
                '¿Aceptas el uso de tus datos para este fin?',
                style: TextStyle(color: Color(0xFFC5BFBF), fontSize: 21, height: 1.5),
              ),
              // ↑↑↑ Edita aquí el texto del aviso de consentimiento ↑↑↑
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      Row(
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
                              style: TextStyle(color: Color(0xFFFF542F), fontWeight: FontWeight.bold, fontSize: 22),
                            ),
                          ),
                          if (!timerDetenido) ...[
                            const SizedBox(width: 8),
                            Text(
                              '($segundosRestantes)',
                              style: const TextStyle(
                                color: Color(0xFFFF542F),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ],
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
                        child: const Text(
                          'Regresar',
                          style: TextStyle(color: Color(0xFF999494), fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      // Se detiene el auto-aceptar: el usuario está leyendo, no ignorando.
                      detenerTimer();
                      setState(() {});
                      mostrarTerminosYCondiciones(context);
                    },
                    child: const Text(
                      'Términos y condiciones',
                      style: TextStyle(
                        color: Color(0xFF999494),
                        fontSize: 15,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF999494),
                      ),
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

/// Muestra el diálogo con los términos y condiciones de uso.
Future<void> mostrarTerminosYCondiciones(BuildContext context) async {
  final anchoDialogo = math.min(MediaQuery.of(context).size.width * 0.9, 640.0);

  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF211D1D),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 14),
        contentPadding: const EdgeInsets.fromLTRB(28, 0, 28, 22),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        actionsAlignment: MainAxisAlignment.center,
        title: const Row(
          children: [
            Icon(Icons.description_outlined, color: Color(0xFFFF542F), size: 32),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Términos y condiciones',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: anchoDialogo,
          height: MediaQuery.of(context).size.height * 0.55,
          child: Scrollbar(
            child: SingleChildScrollView(
              // ↓↓↓ TEXTO DE REFERENCIA: sustituye este contenido por los términos y condiciones reales ↓↓↓
              child: const Text(
                'Este texto es de referencia y debe sustituirse por los términos y condiciones '
                'legales definitivos antes de publicar la aplicación.\n\n'
                '1. Objeto\n'
                'Los presentes términos regulan el uso del kiosco de autoservicio y el tratamiento '
                'de los datos proporcionados por el usuario durante su registro y acceso a las '
                'instalaciones.\n\n'
                '2. Datos que recabamos\n'
                'Para el proceso de registro se podrán recabar, entre otros: nombre completo, '
                'fotografía del rostro, identificación oficial (INE u otro documento) y datos de '
                'contacto asociados a la unidad o domicilio.\n\n'
                '3. Finalidad del tratamiento\n'
                'Los datos se utilizan exclusivamente para validar la identidad del usuario, '
                'gestionar el acceso a las instalaciones y mantener un registro de seguridad de '
                'ingresos y salidas.\n\n'
                '4. Conservación y seguridad\n'
                'La información se almacena de forma segura y se conserva únicamente durante el '
                'tiempo necesario para cumplir con la finalidad descrita o lo que exija la '
                'normativa aplicable.\n\n'
                '5. Derechos del usuario\n'
                'El usuario puede solicitar en cualquier momento el acceso, rectificación o '
                'eliminación de sus datos personales a través de la administración del condominio '
                'o fraccionamiento.\n\n'
                '6. Contacto\n'
                'Para dudas relacionadas con el uso de tus datos, contacta a la administración '
                'del sitio.',
                style: TextStyle(color: Color(0xFFC5BFBF), fontSize: 16, height: 1.6),
              ),
              // ↑↑↑ TEXTO DE REFERENCIA ↑↑↑
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Color(0xFFFF542F), fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      );
    },
  );
}
