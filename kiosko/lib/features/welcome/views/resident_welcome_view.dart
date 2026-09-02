import 'dart:async';

import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/marca_badge.dart';
import 'package:kigo_kiosco/core/widgets/pantalla_adaptable.dart';
import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/registro/services/text_to_speak_servicio.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/resident_welcome_viewmodel.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/services/led_servicio.dart';
import 'package:kigo_kiosco/core/services/relay_servicio.dart';

class ResidentWelcomeView extends StatefulWidget {
  final ResidentWelcomeViewModel viewModel;

  const ResidentWelcomeView({super.key, required this.viewModel});

  @override
  State<ResidentWelcomeView> createState() => _ResidentWelcomeViewState();
}

class _ResidentWelcomeViewState extends State<ResidentWelcomeView> {
  Timer? _timerRegreso;
  final TextToSpeakServicio _tts = TextToSpeakServicio();
  final LedServicio _led = LedServicio();
  final RelayServicio _relay = RelayServicio();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _led.mostrarAprobado();
      _relay.abrir();
      final config = context.read<KioskoConfigNotifier>().config;
      final segs = config.tiempoExitoSeg > 0 ? config.tiempoExitoSeg : 4;
      _timerRegreso = Timer(Duration(seconds: segs), () {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
      _tts.speak('¡Bienvenido, ${widget.viewModel.nombre}! Acceso autorizado.');
    });
  }

  @override
  void dispose() {
    _timerRegreso?.cancel();
    _led.apagar();
    super.dispose();
  }

  ResidentWelcomeViewModel get viewModel => widget.viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.kBg,
      body: PantallaAdaptable(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 48),
        child: Column(
          children: [
            _buildHeader(),

            const Spacer(),

            _buildWelcomeContent(),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const MarcaBadge(lado: 48),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.t(context, 'kigo_label'),
              style: TextStyle(
                color: context.kTextPrimary,
                fontSize: 29,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.t(context, 'self_checkin_label'),
              style: TextStyle(
                color: context.kTextSecondary,
                fontSize: 14,
                letterSpacing: 4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeContent() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: KigoDesign.brand.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: KigoDesign.brand.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.home_rounded,
            color: KigoDesign.brand,
            size: 52,
          ),
        ),

        const SizedBox(height: 36),

        Text(
          AppLocalizations.t(context, 'bienvenido_exclamacion'),
          style: TextStyle(
            color: context.kTextPrimary,
            fontSize: 46,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          viewModel.nombre,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.kTextPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),

        if (viewModel.casaDestino.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            viewModel.casaDestino,
            style: TextStyle(
              color: context.kTextSecondary,
              fontSize: 18,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],

      ],
    );
  }

}
