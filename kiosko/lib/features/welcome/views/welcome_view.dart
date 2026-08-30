/* VISTA PRINCIPAL DE BIENVENIDA */
import 'dart:async';

import 'package:kigo_kiosco/features/registro/views/touch_register_view.dart';
import 'package:kigo_kiosco/features/welcome/views/operator_exit_pin_view.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/operator_exit_viewmodel.dart';
import 'package:kigo_kiosco/features/residente/views/residente_acceso_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/routing/registro_router.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/boton_asistente_flotante.dart';
import 'package:kigo_kiosco/core/widgets/pantalla_adaptable.dart';
import 'package:kigo_kiosco/core/widgets/presionable.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/welcome_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/widgets/comunidad_badge.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

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

    return Stack(
      children: [
        Scaffold(
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _iniciarConteoSalidaOperador(),
            onTapUp: (_) => _cancelarConteoSalidaOperador(),
            onTapCancel: _cancelarConteoSalidaOperador,
            child: PantallaAdaptable(
              padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 48),
              child: Column(
                children: [
                  _buildHeader(context),
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
        BotonAsistenteFlotante(
          onRespuestaLibre: (_) {}, // la respuesta ya se leyó por TTS dentro de AsistenteServicio
          onCampoExtraido: (_) {}, // WelcomeView no llena campos — tipoCampo queda null
        ),
      ],
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
                    KigoDesign.brand.withValues(alpha: 0.30),
                    KigoDesign.brand.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: KigoDesign.brand.withValues(alpha: 0.22),
                    border: Border.all(
                      color: KigoDesign.brand.withValues(alpha: 0.65),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.waving_hand_rounded,
                    color: KigoDesign.brand,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Título principal
        Text(
          AppLocalizations.t(context, 'bienvenido_title'),
          style: TextStyle(
            color: context.kTextPrimary,
            fontSize: 52,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            height: 1,
          ),
        ),

        // Nombre de la comunidad desde la config
        if (mensaje.isNotEmpty) ...[
          const SizedBox(height: 16),
          ComunidadBadge(mensaje: mensaje),
        ],

        const SizedBox(height: 18),

        // Línea decorativa y subtítulo
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLinea(),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  AppLocalizations.t(context, 'selecciona_como_continuar'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.kTextTertiary,
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
            context.kTextTertiary.withValues(alpha: 0.5),
          ]),
        ),
      );

  Widget _buildBotones(BuildContext context) {
    final options = widget.viewModel.options;
    return Row(
      children: [
        Expanded(
            child: _buildBoton(context, options[0].id, options[0].icon,
                AppLocalizations.t(context, options[0].titleKey))),
        const SizedBox(width: 20),
        Expanded(
            child: _buildBoton(context, options[1].id, options[1].icon,
                AppLocalizations.t(context, options[1].titleKey))),
      ],
    );
  }

  Widget _buildBoton(
      BuildContext context, String id, IconData icono, String label) {
    const orange = KigoDesign.brand;
    const orangeLight = KigoDesign.brandHover;
    final gray = context.kSurface2;

    final bool presionado = _presionadoId == id;

    return GestureDetector(
      onTapDown: (_) => setState(() => _presionadoId = id),
      onTapUp: (_) {
        setState(() => _presionadoId = null);
        widget.viewModel.selectOption(id);
        final navigator = Navigator.of(context);
        final config = context.read<KioskoConfigNotifier>().config;
        Future.delayed(const Duration(milliseconds: 160), () {
          if (id == 'visitante') {
            // El QR ya se ofrece en la pantalla principal del kiosko — llegar
            // aquí significa que la visita no trae ninguno, así que se salta
            // directo al registro sin invitación.
            navigator.push(MaterialPageRoute(
              builder: (_) => RegistroRouter.paraVisitante(config),
            ));
          } else if (id == 'residente') {
            navigator.push(MaterialPageRoute(
              builder: (_) => const ResidenteAccesoView(),
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
                color: presionado ? Colors.white : context.kTextPrimary,
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Presionable(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: KigoDesign.brand,
              borderRadius: BorderRadius.circular(KigoDesign.radius),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const Spacer(),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: KigoDesign.brand,
            borderRadius: BorderRadius.circular(KigoDesign.radius),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.t(context, 'kigo_label'),
                style: TextStyle(
                    color: context.kTextPrimary,
                    fontSize: 29,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(AppLocalizations.t(context, 'self_checkin_label'),
                style: TextStyle(
                    color: context.kTextSecondary,
                    fontSize: 14,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const Spacer(),
        // El botón del asistente ya no vive aquí -- flota sobre toda la
        // pantalla vía BotonAsistenteFlotante (mismo lugar en las 3
        // pantallas que lo usan). Este espacio se conserva para que el
        // bloque de logo + nombre siga centrado igual que antes.
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _buildFooter() {
    return Text(
      AppLocalizations.t(context, 'footer_text'),
      style: TextStyle(
        color: context.kTextTertiary,
        fontSize: 14,
        letterSpacing: 2,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
