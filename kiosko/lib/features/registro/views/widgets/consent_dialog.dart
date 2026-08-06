/* VENTANA DE CONSENTIMIENTO */

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Muestra un diálogo de consentimiento de uso de datos antes de activar la cámara.
/// Retorna `true` si el usuario acepta, `false` si decide regresar.
Future<bool> mostrarConsentimientoCamara(BuildContext context) async {
  final bool? aceptado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      final anchoDialogo = math.min(MediaQuery.of(context).size.width * 0.9, 640.0);

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
            'Estas a punto de confiarnos datos sencibles para acceder a las instalaciones. '
            'La imagen será capturada de forma local en este dispositivo únicamente'
            'para validar tu identidad. Mantendremos y cuidaremos tus datos durante '
            '/// para después eliminarlos. \n\n'
            '¿Aceptas el uso de tus datos para este fin?',
            style: TextStyle(color: Color(0xFFC5BFBF), fontSize: 21, height: 1.5),
          ),
          // ↑↑↑ Edita aquí el texto del aviso de consentimiento ↑↑↑
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Regresar',
              style: TextStyle(color: Color(0xFF999494), fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Aceptar',
              style: TextStyle(color: Color(0xFFFF542F), fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ),
        ],
      );
    },
  );

  return aceptado ?? false;
}
