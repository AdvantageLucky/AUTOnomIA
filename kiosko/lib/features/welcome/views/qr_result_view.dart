import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/services/led_servicio.dart';
import 'package:kigo_kiosco/core/widgets/boton_asistente_flotante.dart';
import 'package:kigo_kiosco/core/widgets/presionable.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/pantalla_adaptable.dart';
import 'package:kigo_kiosco/features/registro/services/text_to_speak_servicio.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/qr_result_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/widgets/kigo_wordmark.dart';
import 'package:kigo_kiosco/features/welcome/views/widgets/verdict_ring.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';

class QrResultView extends StatefulWidget {
  final QrResultViewModel viewModel;

  /// Si no es null, se llama solo tras ~5s en un estado terminal — usado
  /// cuando esta pantalla se alcanzó desde la entrada principal del kiosko,
  /// para volver a escanear con el siguiente visitante sin esperar un toque.
  final VoidCallback? alTerminar;

  const QrResultView({super.key, required this.viewModel, this.alTerminar});

  @override
  State<QrResultView> createState() => _QrResultViewState();
}

class _QrResultViewState extends State<QrResultView> {
  Timer? _autoTimer;
  final _led = LedServicio();
  final _tts = TextToSpeakServicio();
  bool _ledDisparado = false;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_updateView);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateView());
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_updateView);
    _autoTimer?.cancel();
    _led.apagar();
    super.dispose();
  }

  void _updateView() {
    setState(() {});
    if (!_ledDisparado && widget.viewModel.estado != QrResultEstado.cargando) {
      _ledDisparado = true;
      if (widget.viewModel.estado == QrResultEstado.exitoso) {
        _led.mostrarAprobado();
        _tts.speak('Acceso autorizado. ¡Bienvenido!');
      } else {
        _led.mostrarRechazado();
        _tts.speak('Invitación no válida o expirada.');
      }
    }
    if (_autoTimer == null &&
        widget.alTerminar != null &&
        widget.viewModel.estado != QrResultEstado.cargando) {
      final config = context.read<KioskoConfigNotifier>().config;
      final segs = config.tiempoExitoSeg > 0 ? config.tiempoExitoSeg : 4;
      _autoTimer = Timer(Duration(seconds: segs), widget.alTerminar!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: PantallaAdaptable(
            child: Column(
              children: [
                const KigoWordmark(),
                const Spacer(),
                _buildContent(),
                const Spacer(),
                _buildFooter(),
              ],
            ),
          ),
        ),
        BotonAsistenteFlotante(
          // Coincide con el padding por default de PantallaAdaptable (34/24).
          topDelBorde: 24,
          rightDelBorde: 34,
          onRespuestaLibre: (_) {},
          onCampoExtraido: (_) {},
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (widget.viewModel.estado) {
      case QrResultEstado.cargando:
        return _buildCargando();
      case QrResultEstado.exitoso:
        return _buildExitoso();
      case QrResultEstado.error:
        return _buildError();
    }
  }

  Widget _buildCargando() {
    return Column(
      children: [
        const SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(color: KigoDesign.brand, strokeWidth: 3),
        ),
        const SizedBox(height: 36),
        Text(
          AppLocalizations.t(context, 'verificando_invitacion'),
          style: TextStyle(color: context.kTextPrimary, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildExitoso() {
    final h = MediaQuery.sizeOf(context).height;
    final iconSize = (h * 0.14).clamp(70.0, 110.0);
    final gap = (h * 0.04).clamp(10.0, 36.0);
    return Column(
      children: [
        VerdictRing(color: KigoDesign.success, icon: Icons.check_rounded, size: iconSize),
        SizedBox(height: gap),
        Text(AppLocalizations.t(context, 'acceso_concedido'), style: TextStyle(color: context.kTextPrimary, fontSize: (h * 0.048).clamp(22.0, 38.0), fontWeight: FontWeight.w800)),
        SizedBox(height: gap * 0.4),
        if (widget.viewModel.titular != null)
          Text(
            widget.viewModel.titular!,
            style: const TextStyle(color: KigoDesign.success, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1),
          ),
        if (widget.viewModel.casaDestino != null && widget.viewModel.casaDestino!.isNotEmpty) ...[
          SizedBox(height: gap * 0.22),
          Text(
            widget.viewModel.casaDestino!,
            style: TextStyle(color: context.kTextSecondary, fontSize: 16, letterSpacing: 2),
          ),
        ],
        SizedBox(height: gap),
        Text(
          AppLocalizations.t(context, 'puedes_ingresar_evento_bienvenido'),
          textAlign: TextAlign.center,
          style: TextStyle(color: context.kTextSecondary, fontSize: 17, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildError() {
    final h = MediaQuery.sizeOf(context).height;
    final iconSize = (h * 0.14).clamp(70.0, 110.0);
    final gap = (h * 0.04).clamp(10.0, 36.0);
    return Column(
      children: [
        VerdictRing(color: KigoDesign.error, icon: Icons.close_rounded, size: iconSize),
        SizedBox(height: gap),
        Text(AppLocalizations.t(context, 'acceso_denegado'), style: TextStyle(color: context.kTextPrimary, fontSize: (h * 0.044).clamp(20.0, 34.0), fontWeight: FontWeight.w800)),
        SizedBox(height: gap * 0.4),
        Text(
          widget.viewModel.errorMsg ?? AppLocalizations.t(context, 'invitacion_no_valida'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: KigoDesign.error, fontSize: 16, height: 1.5),
        ),
        SizedBox(height: gap),
        Presionable(
          onTap: () {
            _autoTimer?.cancel();
            if (widget.alTerminar != null) {
              widget.alTerminar!();
            } else {
              Navigator.pop(context);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: context.kSurface2,
              borderRadius: BorderRadius.circular(KigoDesign.radiusLg),
              border: Border.all(color: context.kBorder),
            ),
            child: Text(AppLocalizations.t(context, 'volver_a_intentar'), style: TextStyle(color: context.kTextPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Text(
      AppLocalizations.t(context, 'footer_text'),
      style: TextStyle(color: context.kTextTertiary, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.w500),
    );
  }
}
