import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'identidad/checkpoint_sweep.dart';

/// Hero de la pantalla de bienvenida: una credencial de acceso -- la misma
/// metáfora que ya usa toda la app (código de instalación, PIN, QR) llevada
/// a una tarjeta física verificándose. Reusa CheckpointSweep, el mismo
/// barrido que ya corre sobre la INE al escanearla, para que el primer
/// vistazo a la app ya hable el mismo idioma visual que el resto del flujo.
///
/// A diferencia del hero anterior (un brazo de barrera que rotaba sobre un
/// pivote), aquí no hay ninguna pieza mecánica en movimiento -- solo una
/// entrada de fade+escala una sola vez y el barrido en loop ya probado en
/// otra pantalla. Menos geometría propia significa menos superficie para
/// el tipo de bug de recorte que tuvo el diseño anterior.
class CredencialAccesoAnimada extends StatefulWidget {
  const CredencialAccesoAnimada({super.key});

  @override
  State<CredencialAccesoAnimada> createState() =>
      _CredencialAccesoAnimadaState();
}

class _CredencialAccesoAnimadaState extends State<CredencialAccesoAnimada>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrada;
  late final Animation<double> _escala;
  late final Animation<double> _opacidad;

  @override
  void initState() {
    super.initState();
    _entrada = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _escala = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _entrada, curve: Curves.easeOutCubic));
    _opacidad = CurvedAnimation(
        parent: _entrada,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _entrada.forward();
    });
  }

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTarjeta = esOscuro ? AppTheme.cardDark : AppTheme.surfaceLight;
    final colorBorde = esOscuro ? AppTheme.borderDark : AppTheme.borderLight;
    final colorTexto = esOscuro ? AppTheme.textWhite : AppTheme.textDark;

    return AnimatedBuilder(
      animation: _entrada,
      builder: (context, child) => Opacity(
        opacity: _opacidad.value,
        child: Transform.scale(scale: _escala.value, child: child),
      ),
      child: Center(
        child: ConstrainedBox(
          // El maxWidth debe fijarse ANTES de AspectRatio -- AspectRatio ya
          // entrega una constraint tight a su hijo, así que un maxWidth en
          // el Container de más adentro no hace nada (la tarjeta salía a
          // casi todo el ancho de pantalla en vez de tamaño de credencial).
          constraints: const BoxConstraints(maxWidth: 300),
          child: Transform.rotate(
            angle: -0.045,
            child: AspectRatio(
              aspectRatio:
                  1.586, // proporción estándar de una credencial física
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: colorTarjeta,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: colorBorde),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.16),
                      blurRadius: 32,
                      spreadRadius: -6,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryOrange,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.home_rounded,
                                      size: 14, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'KIGO',
                                  style: TextStyle(
                                    fontFamily: 'Unbounded',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                    color: colorTexto,
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.wifi_rounded,
                                    size: 15,
                                    color: colorTexto.withValues(alpha: 0.35)),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.primaryOrange
                                        .withValues(alpha: 0.12),
                                    border: Border.all(
                                        color: AppTheme.primaryOrange
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: const Icon(Icons.person_rounded,
                                      size: 18, color: AppTheme.primaryOrange),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Acceso residente',
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                          color: colorTexto,
                                        ),
                                      ),
                                      Text(
                                        'Verificando comunidad…',
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: 10.5,
                                          color: colorTexto.withValues(
                                              alpha: 0.55),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                                height: 16,
                                child: CustomPaint(
                                    painter: _CodigoBarrasPainter(
                                        colorBorde: colorBorde))),
                          ],
                        ),
                      ),
                      Positioned.fill(
                          child: CheckpointSweep(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusLg))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tira de barras decorativa (sin datos reales) -- referencia visual al
/// código de instalación / QR que ya vertebra el resto de la app.
class _CodigoBarrasPainter extends CustomPainter {
  final Color colorBorde;
  _CodigoBarrasPainter({required this.colorBorde});

  // Ancho de cada barra fijo (seed manual, no random) para que sea igual en
  // cada rebuild y no "titile" con cada frame del CheckpointSweep de encima.
  static const _anchos = [
    2.0,
    1.0,
    3.0,
    1.0,
    1.0,
    4.0,
    2.0,
    1.0,
    2.0,
    3.0,
    1.0,
    2.0,
    1.0,
    4.0,
    1.0,
    2.0,
    3.0,
    1.0,
    2.0,
    1.0
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paintBase = Paint()..color = colorBorde;
    final paintAcento = Paint()
      ..color = AppTheme.primaryOrange.withValues(alpha: 0.7);
    double x = 0;
    final espacio =
        size.width / (_anchos.fold<double>(0, (a, b) => a + b + 2.2));
    for (var i = 0; i < _anchos.length; i++) {
      final w = _anchos[i] * espacio;
      canvas.drawRect(
        Rect.fromLTWH(x, 0, w, size.height),
        (i == 5 || i == 13) ? paintAcento : paintBase,
      );
      x += w + 2.2 * espacio;
    }
  }

  @override
  bool shouldRepaint(_CodigoBarrasPainter oldDelegate) => false;
}
