import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';

/// Los 3 estados que ya maneja `BotonAsistente` — se repite aquí en vez de
/// importarlo desde ahí porque el enum original es privado a ese archivo
/// (`_EstadoAsistente`); este widget no necesita saber nada más del
/// asistente que "en cuál de los tres estados estoy".
enum EstadoMascota { inactivo, escuchando, procesando, hablando }

/// Mascota vectorial del asistente: una carita redonda sobre un pequeño
/// pedestal, sin brazos ni piernas -- la referencia exacta que pidió el
/// usuario es el asistente de configuración de internet de Wii/DS (dos
/// puntos por ojos, una curva por boca, flotando sobre una base blanca).
/// Deliberadamente simple: nada de gradientes ni sombras complejas, calca
/// esa economía de trazo a propósito -- y de paso es la opción más liviana
/// para un F10 de 2GB de RAM (CustomPainter puro, cero assets que cargar).
class MascotaAsistente extends StatelessWidget {
  final EstadoMascota estado;

  /// 0..1, sube y baja en bucle -- respira/parpadea según el estado.
  final double pulseValue;

  /// 0..1, avanza en bucle -- anima los puntos de "procesando".
  final double rotValue;

  /// Lado del cuadro donde se dibuja. El painter escala todo desde el
  /// viewBox 60x60 del mockup, asi que cualquier valor sale proporcionado.
  final double lado;

  const MascotaAsistente({
    super.key,
    required this.estado,
    required this.pulseValue,
    required this.rotValue,
    this.lado = KigoDesign.ladoAsistente,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(lado, lado),
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

    final pedestalPaint = Paint()..color = Colors.white.withValues(alpha: 0.92);

    // Pedestal de dos niveles -- es lo que le da presencia sin necesitar
    // brazos ni piernas, igual que la referencia.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p(30, 55), width: 16 * s, height: 5 * s),
        Radius.circular(2.5 * s),
      ),
      pedestalPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p(30, 49), width: 7 * s, height: 8 * s),
        Radius.circular(2 * s),
      ),
      pedestalPaint,
    );

    // La cabeza "respira" un poco mientras escucha -- sube y baja sobre el
    // pedestal, nunca lo abandona.
    final bounce = estado == EstadoMascota.escuchando ? -1.5 * pulseValue * s : 0.0;
    canvas.save();
    canvas.translate(0, bounce);

    // Cabeza: blob redondeado, más ancho que alto -- no una esfera ni un
    // óvalo perfecto, calcado de la proporción del mockup.
    final cabezaPaint = Paint()..color = KigoDesign.brand;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p(30, 28), width: 34 * s, height: 28 * s),
        Radius.circular(15 * s),
      ),
      cabezaPaint,
    );

    _pintarCara(canvas, p, s);

    canvas.restore();

    // Procesando: tres puntos parpadeando en cascada bajo la cabeza -- el
    // lenguaje de "escribiendo..." de un chat, no un spinner de carga.
    if (estado == EstadoMascota.procesando) {
      final puntoPaint = Paint()..color = Colors.white;
      for (var i = 0; i < 3; i++) {
        final fase = (rotValue * 3 - i) % 1.0;
        final alpha = (0.3 + 0.7 * (1 - (fase - 0.5).abs() * 2)).clamp(0.3, 1.0);
        canvas.drawCircle(
          p(24.0 + i * 6, 55),
          1.6 * s,
          puntoPaint..color = Colors.white.withValues(alpha: alpha),
        );
      }
    }
  }

  void _pintarCara(Canvas canvas, Offset Function(double, double) p, double s) {
    // Ojos: puntos simples, un poco más grandes y separados mientras
    // escucha -- "más atenta", mismo lenguaje que ya usaba el resto de la
    // app.
    final ojoPaint = Paint()..color = Colors.white;
    final ojoRadio = (estado == EstadoMascota.escuchando ? 2.8 : 2.3) * s;
    final ojoY = estado == EstadoMascota.escuchando ? 26.0 : 27.0;
    canvas.drawCircle(p(22.5, ojoY), ojoRadio, ojoPaint);
    canvas.drawCircle(p(37.5, ojoY), ojoRadio, ojoPaint);

    final bocaPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round;

    switch (estado) {
      case EstadoMascota.inactivo:
        // Sonrisa fija, curva simple -- exactamente la cara de la
        // referencia en reposo.
        final camino = Path()
          ..moveTo(p(24, 35).dx, p(24, 35).dy)
          ..quadraticBezierTo(p(30, 40).dx, p(30, 40).dy, p(36, 35).dx, p(36, 35).dy);
        canvas.drawPath(camino, bocaPaint);
      case EstadoMascota.escuchando:
        // Boca pequeña y redonda -- atenta, no hablando.
        canvas.drawCircle(p(30, 37), (2.2 + 1 * pulseValue) * s, Paint()..color = Colors.white);
      case EstadoMascota.procesando:
        // Línea recta y neutral: está pensando, no sonriendo ni hablando.
        canvas.drawLine(p(25, 37), p(35, 37), bocaPaint);
      case EstadoMascota.hablando:
        // Óvalo que se abre y cierra con pulseValue -- la única boca que
        // cambia de tamaño en bucle, para que se lea claro "está hablando".
        canvas.drawOval(
          Rect.fromCenter(center: p(30, 37), width: 11 * s, height: (2.5 + 5 * pulseValue) * s),
          Paint()..color = Colors.white,
        );
    }
  }

  @override
  bool shouldRepaint(_MascotaPainter oldDelegate) =>
      oldDelegate.estado != estado ||
      oldDelegate.pulseValue != pulseValue ||
      oldDelegate.rotValue != rotValue;
}
