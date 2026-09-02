import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/marca_badge.dart';

/// Marca mínima de esquina — reemplaza el lockup grande "Kigo / SELF
/// CHECK-IN" repetido en cada pantalla del flujo QR. El veredicto de cada
/// pantalla (escaneando / acceso concedido / denegado) es el protagonista;
/// esto solo confirma en qué app estás, en voz baja.
class KigoWordmark extends StatelessWidget {
  /// Color del texto "AUTOnomIA". `null` lo resuelve contra el tema activo, que es
  /// lo que quieren las pantallas montadas sobre el fondo de la app; las que
  /// van sobre la cámara siguen pasando un color fijo.
  final Color? color;

  /// Multiplica el lockup completo. Las pantallas de resultado lo dejan en 1
  /// —ahí la marca va en voz baja—; la de escaneo lo sube, porque sobre el
  /// fondo liso es lo único que acompaña al recuadro.
  final double escala;

  const KigoWordmark({
    super.key,
    this.color,
    this.escala = 1,
  });

  @override
  Widget build(BuildContext context) {
    final lado = 26 * escala;
    final colorTexto = color ?? context.kTextPrimary;
    // "AUTOnomIA" es bastante más largo que "Kigo" -- en pantallas angostas
    // (o con escala alta, ver qr_scanner_view) desbordaba el Row. FittedBox
    // lo achica solo lo necesario en vez de recortarse o tronar el layout.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MarcaBadge(lado: lado),
          SizedBox(width: 8 * escala),
          Text(
            'AUTOnomIA',
            style: TextStyle(
              fontFamily: 'Unbounded',
              color: colorTexto,
              fontSize: 15 * escala,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2 * escala,
            ),
          ),
        ],
      ),
    );
  }
}
