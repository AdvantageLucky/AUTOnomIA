/* VISTA PRINCIPAL DE BIENVENIDA */
import 'dart:async';
import 'dart:math' as math;

import 'package:kigo_kiosco/features/registro/views/touch_register_view.dart';
import 'package:kigo_kiosco/features/welcome/views/visitor_type_view.dart';
import 'package:kigo_kiosco/features/welcome/views/resident_pin_view.dart';
import 'package:kigo_kiosco/features/welcome/views/operator_exit_pin_view.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/visitor_type_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/resident_pin_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/operator_exit_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/welcome_viewmodel.dart';

class WelcomeView extends StatefulWidget {
  final WelcomeViewModel viewModel;

  const WelcomeView({
    super.key,
    required this.viewModel,
  });

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView>
    with TickerProviderStateMixin {
  String? _presionadoId;
  Timer? _salidaOperadorTimer;

  late final AnimationController _entradaCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_updateView);

    _entradaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _entradaCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entradaCtrl, curve: Curves.easeOutCubic));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.72, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _entradaCtrl.forward();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_updateView);
    _salidaOperadorTimer?.cancel();
    _entradaCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _updateView() => setState(() {});

  // Mantener presionada la pantalla de bienvenida 5s abre el PIN de
  // operador para salir del modo kiosko; un toque normal nunca llega a los 5s.
  void _iniciarConteoSalidaOperador() {
    _salidaOperadorTimer?.cancel();
    _salidaOperadorTimer = Timer(const Duration(seconds: 5), _abrirSalidaOperador);
  }

  void _cancelarConteoSalidaOperador() {
    _salidaOperadorTimer?.cancel();
    _salidaOperadorTimer = null;
  }

  void _abrirSalidaOperador() {
    _salidaOperadorTimer = null;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => OperatorExitPinView(viewModel: OperatorExitViewModel()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cfg = context.watch<KioskoConfigNotifier>().config;
    final mensaje = cfg.mensajeBienvenida.trim();

    return Scaffold(
      backgroundColor: const Color(0xFF171313),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _iniciarConteoSalidaOperador(),
        onTapUp: (_) => _cancelarConteoSalidaOperador(),
        onTapCancel: _cancelarConteoSalidaOperador,
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 48),
            child: Column(
              children: [
                _buildHeader(),
                const Spacer(),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _buildWelcomeSection(mensaje),
                  ),
                ),
                const SizedBox(height: 56),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildBotones(context),
                ),
                const Spacer(),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String mensaje) {
    return Column(
      children: [
        // Orbe decorativo animado
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) => Transform.scale(
            scale: _pulseAnim.value,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF542F).withValues(alpha: 0.30),
                    const Color(0xFFFF542F).withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF542F).withValues(alpha: 0.22),
                    border: Border.all(
                      color: const Color(0xFFFF542F).withValues(alpha: 0.65),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.waving_hand_rounded,
                    color: Color(0xFFFF542F),
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Título principal
        const Text(
          'Bienvenido',
          style: TextStyle(
            color: Colors.white,
            fontSize: 52,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            height: 1,
          ),
        ),

        // Nombre de la comunidad desde la config
        if (mensaje.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ComunidadBadge(mensaje: mensaje),
        ],

        const SizedBox(height: 18),

        // Línea decorativa y subtítulo
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLinea(),
            const Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'SELECCIONA CÓMO QUIERES CONTINUAR',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF6B6464),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ),
            _buildLinea(),
          ],
        ),
      ],
    );
  }

  Widget _buildLinea() => Container(
        width: 28,
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent,
            const Color(0xFF6B6464).withValues(alpha: 0.5),
          ]),
        ),
      );

  Widget _buildBotones(BuildContext context) {
    final options = widget.viewModel.options;
    return Row(
      children: [
        Expanded(
            child: _buildBoton(
                context, options[0].id, options[0].icon, options[0].title)),
        const SizedBox(width: 20),
        Expanded(
            child: _buildBoton(
                context, options[1].id, options[1].icon, options[1].title)),
      ],
    );
  }

  Widget _buildBoton(
      BuildContext context, String id, IconData icono, String label) {
    const orange = Color(0xFFFF542F);
    const orangeLight = Color(0xFFFF714D);
    const gray = Color(0xFF2B2727);

    final bool presionado = _presionadoId == id;

    return GestureDetector(
      onTapDown: (_) => setState(() => _presionadoId = id),
      onTapUp: (_) {
        setState(() => _presionadoId = null);
        widget.viewModel.selectOption(id);
        final navigator = Navigator.of(context);
        Future.delayed(const Duration(milliseconds: 160), () {
          if (id == 'visitante') {
            navigator.push(MaterialPageRoute(
              builder: (_) => VisitorTypeView(viewModel: VisitorTypeViewModel()),
            ));
          } else if (id == 'residente') {
            navigator.push(MaterialPageRoute(
              builder: (_) =>
                  ResidentPinView(viewModel: ResidentPinViewModel()),
            ));
          } else {
            navigator.push(
                MaterialPageRoute(builder: (_) => const TouchRegisterView()));
          }
        });
      },
      onTapCancel: () => setState(() => _presionadoId = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 160,
        decoration: BoxDecoration(
          color: presionado ? orangeLight : gray,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color:
                presionado ? orangeLight : orange.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: presionado
              ? [
                  BoxShadow(
                    color: orange.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono,
                color: presionado ? Colors.white : orange, size: 72),
            const SizedBox(height: 14),
            Text(
              label,
              style: TextStyle(
                color: presionado ? Colors.white : const Color(0xFFD0CBCB),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFF542F),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text('K',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kigo',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text('SELF CHECK-IN',
                style: TextStyle(
                    color: Color(0xFF8A8585),
                    fontSize: 14,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return const Text(
      'POWERED BY KIGO · FEPRO 2026',
      style: TextStyle(
        color: Color(0xFF595252),
        fontSize: 14,
        letterSpacing: 2,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Badge animado con el nombre de la comunidad que viene de la config del kiosko.
class _ComunidadBadge extends StatefulWidget {
  final String mensaje;
  const _ComunidadBadge({required this.mensaje});

  @override
  State<_ComunidadBadge> createState() => _ComunidadBadgeState();
}

class _ComunidadBadgeState extends State<_ComunidadBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, child) {
        final angle = _shimmerCtrl.value * 2 * math.pi;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: LinearGradient(
              begin: Alignment(math.cos(angle), math.sin(angle)),
              end: Alignment(-math.cos(angle), -math.sin(angle)),
              colors: const [
                Color(0x22FF542F),
                Color(0x0AFF8C70),
                Color(0x22FF542F),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFFF542F).withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFF542F),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              widget.mensaje,
              style: const TextStyle(
                color: Color(0xFFFF9070),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFF542F),
            ),
          ),
        ],
      ),
    );
  }
}
