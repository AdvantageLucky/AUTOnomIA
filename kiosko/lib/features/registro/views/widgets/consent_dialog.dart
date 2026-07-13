/* VENTANA DE CONSENTIMIENTO */

import 'package:flutter/material.dart';

/// Muestra un diálogo de consentimiento de uso de datos antes de activar la cámara.
/// Retorna `true` si el usuario acepta, `false` si decide regresar.
Future<bool> mostrarConsentimientoCamara(BuildContext context) async {
  final bool? aceptado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF211D1D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: Color(0xFFFF542F), size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Consentimiento de datos',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Estas a punto de confiarnos datos sencibles para acceder a las instalaciones '
          'la imagen capturada de forma local en este dispositivo, únicamente es'
          'para validar tu identidad.\n\n¿Aceptas el uso de tus datos para este fin?',
          style: TextStyle(color: Color(0xFFC5BFBF), fontSize: 16, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Regresar',
              style: TextStyle(color: Color(0xFF999494), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Aceptar',
              style: TextStyle(color: Color(0xFFFF542F), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      );
    },
  );

  return aceptado ?? false;
}
