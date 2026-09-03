import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Hero animado de la pantalla de entrada: una pluma de acceso vehicular
/// (el mismo objeto físico que un residente cruza todos los días) que sube
/// una sola vez al abrir la pantalla -- el gesto literal de "acceso
/// concedido", no un ícono genérico de candado o huella digital.
///
/// Un solo momento orquestado (subir la pluma + aparecer el wordmark
/// detrás), sin loops ni efectos sueltos por elemento.
class BarreraAccesoAnimada extends StatefulWidget {
  const BarreraAccesoAnimada({super.key});

  @override
  State<BarreraAccesoAnimada> createState() => _BarreraAccesoAnimadaState();
}

class _BarreraAccesoAnimadaState extends State<BarreraAccesoAnimada>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _angulo;
  late final Animation<double> _wordmarkOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _angulo = Tween<double>(begin: 0, end: -1.05).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack)),
    );
    _wordmarkOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    // Un pequeño respiro antes de arrancar -- si sube en el mismo frame en
    // que la pantalla entra, se siente atropellado; el resto del onboarding
    // ya usa este mismo criterio (ver step_escanear_ine.dart en el kiosko).
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Geometría fija del motivo -- coordenadas explícitas (todas `top`/`left`,
  // nunca mezcladas con `bottom`) para que el punto de pivote de la pluma
  // sea inequívoco: exactamente la esquina superior del poste.
  static const _alturaLienzo = 200.0;
  static const _postePosX = 44.0;
  static const _posteAncho = 14.0;
  static const _posteAlto = 84.0;
  static const _posteTopY = 96.0;
  static const _brazoAlto = 16.0;

  @override
  Widget build(BuildContext context) {
    // Un gris medio, no el par surface2Dark/Light -- ese casi desaparece
    // contra un fondo claro (muy poco contraste ahí), mientras que un solo
    // tono intermedio se lee bien contra los dos extremos.
    const postColor = AppTheme.textDimmed;
    const pivoteX = _postePosX + _posteAncho / 2;

    return SizedBox(
      height: _alturaLienzo,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Wordmark, aparece cuando la pluma ya casi terminó de subir.
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _wordmarkOpacity.value,
                  child: Text(
                    'KIGO',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          letterSpacing: 6,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              // Poste, fijo.
              Positioned(
                left: _postePosX,
                top: _posteTopY,
                child: Container(
                  width: _posteAncho,
                  height: _posteAlto,
                  decoration: BoxDecoration(color: postColor, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              // Brazo: pivota exactamente sobre la esquina superior del poste.
              Positioned(
                left: pivoteX,
                top: _posteTopY - _brazoAlto / 2,
                child: Transform.rotate(
                  angle: _angulo.value,
                  alignment: Alignment.centerLeft,
                  child: const _BrazoPluma(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// El brazo de la pluma: una barra con franjas -- referencia directa (no
/// literal rojo/blanco) a la pluma vehicular real del kiosko, en la paleta
/// de marca para que no desentone con el resto de la pantalla.
class _BrazoPluma extends StatelessWidget {
  const _BrazoPluma();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 16,
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(painter: _FranjasPainter()),
    );
  }
}

class _FranjasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    const anchoFranja = 8.0;
    const espacio = 14.0;
    var x = size.width - 22;
    while (x > 8) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x - anchoFranja, 0)
        ..lineTo(x - anchoFranja - size.height, size.height)
        ..lineTo(x - size.height, size.height)
        ..close();
      canvas.drawPath(path, paint);
      x -= espacio;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
