import 'dart:async';

import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/pantalla_adaptable.dart';
import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/resident_welcome_viewmodel.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

class ResidentWelcomeView extends StatefulWidget {
  final ResidentWelcomeViewModel viewModel;

  const ResidentWelcomeView({super.key, required this.viewModel});

  @override
  State<ResidentWelcomeView> createState() => _ResidentWelcomeViewState();
}

class _ResidentWelcomeViewState extends State<ResidentWelcomeView> {
  Timer? _timerRegreso;

  @override
  void initState() {
    super.initState();
    // Tras mostrar la confirmación, regresa sola a la pantalla de bienvenida.
    _timerRegreso = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    _timerRegreso?.cancel();
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

            _buildFooter(),
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
            color: KigoDesign.brand,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text(
              'K',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
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
