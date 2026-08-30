import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';

/// Los 3 estados que ya maneja `BotonAsistente` — se repite aquí en vez de
/// importarlo desde ahí porque el enum original es privado a ese archivo
/// (`_EstadoAsistente`); este widget no necesita saber nada más del
/// asistente que "en cuál de los tres estados estoy".
enum EstadoMascota { inactivo, escuchando, procesando, hablando }

/// Mascota vectorial del asistente: un orbe con antena y carita, inspirado
/// en el asistente animado de Nintendo 3DS que pidió el usuario — sustituye
/// al ícono de micrófono plano. Relleno sólido de marca (no un tono oscuro
/// "de cristal"): un relleno oscuro se pierde contra el fondo negro del
/// kiosko, confirmado en el companion visual de brainstorming.
class MascotaAsistente extends StatelessWidget {
  final EstadoMascota estado;

  /// 0..1, sube y baja en bucle — anima el punto de la antena mientras
  /// escucha.
  final double pulseValue;

  /// 0..1, avanza en bucle — gira el arco de "procesando" alrededor del orbe.
  final double rotValue;

  const MascotaAsistente({
    super.key,
    required this.estado,
    required this.pulseValue,
    required this.rotValue,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(44, 44),
      painter: _MascotaPainter(
        estado: estado,
        pulseValue: pulseValue,
        rotValue: rotValue,
      ),
    );
  }
}

class _MascotaPainter extends CustomPainter {
  final EstadoMascota estado;
  final double pulseValue;
  final double rotValue;

  _MascotaPainter({
    required this.estado,
    required this.pulseValue,
    required this.rotValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Proporciones tomadas 1:1 del mockup aprobado (viewBox 60x60),
    // escaladas al tamaño real del widget.
    final s = size.width / 60;
    Offset p(double x, double y) => Offset(x * s, y * s);

    final orbCentro = p(30, 34);
    final orbRadio = 22 * s;

    final orbPaint = Paint()..color = KigoDesign.brand;
    canvas.drawCircle(orbCentro, orbRadio, orbPaint);

    // Antena: tallo + punta. La punta "respira" (pulseValue) solo mientras
    // escucha; en los otros dos estados queda fija.
    final tallo = Paint()
      ..color = KigoDesign.brand
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p(30, 8), p(30, 14), tallo);

    final puntaRadio = (estado == EstadoMascota.escuchando
            ? 3 + 2 * pulseValue
            : 3) *
        s;
    canvas.drawCircle(p(30, 6), puntaRadio, orbPaint);

    // Ojos: blancos, un poco más grandes mientras escucha (mismo lenguaje
    // que ya usaba el resto de la app: "más grande y firme" = atento).
    final ojoPaint = Paint()..color = Colors.white;
    final ojoRadio = (estado == EstadoMascota.escuchando ? 4 : 3) * s;
    canvas.drawCircle(p(23, 32), ojoRadio, ojoPaint);
    canvas.drawCircle(p(37, 32), ojoRadio, ojoPaint);

    // Procesando: arco blanco semitransparente girando alrededor del orbe.
    if (estado == EstadoMascota.procesando) {
      final arcoPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * s
        ..strokeCap = StrokeCap.round;
      final rect = Rect.fromCircle(center: orbCentro, radius: orbRadio - 4 * s);
      final inicio = rotValue * 2 * 3.14159265;
      canvas.drawArc(rect, inicio, 3.14159265 / 2, false, arcoPaint);
    }

    // Hablando: una boca ovalada bajo los ojos que se abre/cierra con
    // pulseValue -- visualmente distinta del pulso de la antena
    // (escuchando) y del arco girando (procesando), para que el usuario no
    // confunda "ella me habla" con "ella me escucha".
    if (estado == EstadoMascota.hablando) {
      final bocaPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
      final bocaAlto = (2 + 4 * pulseValue) * s;
      final bocaAncho = 10 * s;
      final bocaCentro = p(30, 40);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: bocaCentro, width: bocaAncho, height: bocaAlto),
          Radius.circular(bocaAlto / 2),
        ),
        bocaPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MascotaPainter oldDelegate) =>
      oldDelegate.estado != estado ||
      oldDelegate.pulseValue != pulseValue ||
      oldDelegate.rotValue != rotValue;
}
