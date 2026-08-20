import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/qr_result_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/widgets/kigo_wordmark.dart';
import 'package:kigo_kiosco/features/welcome/views/widgets/verdict_ring.dart';

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

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_updateView);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_updateView);
    _autoTimer?.cancel();
    super.dispose();
  }

  void _updateView() {
    setState(() {});
    if (_autoTimer == null &&
        widget.alTerminar != null &&
        widget.viewModel.estado != QrResultEstado.cargando) {
      _autoTimer = Timer(const Duration(seconds: 5), widget.alTerminar!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final vPad = (constraints.maxHeight * 0.06).clamp(16.0, 48.0);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 34, vertical: vPad),
              child: Column(
                children: [
                  const KigoWordmark(color: KigoDesign.textPrimary),
                  const Spacer(),
                  _buildContent(),
                  const Spacer(),
                  _buildFooter(),
                ],
              ),
            );
          },
        ),
      ),
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
    return const Column(
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(color: KigoDesign.brand, strokeWidth: 3),
        ),
        SizedBox(height: 36),
        Text(
          'Verificando invitación...',
          style: TextStyle(color: KigoDesign.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
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
        Text('¡Acceso concedido!', style: TextStyle(color: KigoDesign.textPrimary, fontSize: (h * 0.048).clamp(22.0, 38.0), fontWeight: FontWeight.w800)),
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
            style: const TextStyle(color: KigoDesign.textSecondary, fontSize: 16, letterSpacing: 2),
          ),
        ],
        SizedBox(height: gap),
        const Text(
          'Puedes ingresar al evento.\nBienvenido.',
          textAlign: TextAlign.center,
          style: TextStyle(color: KigoDesign.textSecondary, fontSize: 17, height: 1.6),
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
        Text('Acceso denegado', style: TextStyle(color: KigoDesign.textPrimary, fontSize: (h * 0.044).clamp(20.0, 34.0), fontWeight: FontWeight.w800)),
        SizedBox(height: gap * 0.4),
        Text(
          widget.viewModel.errorMsg ?? 'La invitación no es válida',
          textAlign: TextAlign.center,
          style: const TextStyle(color: KigoDesign.error, fontSize: 16, height: 1.5),
        ),
        SizedBox(height: gap),
        GestureDetector(
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
              color: KigoDesign.surface2,
              borderRadius: BorderRadius.circular(KigoDesign.radiusLg),
              border: Border.all(color: KigoDesign.border),
            ),
            child: const Text('Volver a intentar', style: TextStyle(color: KigoDesign.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return const Text(
      'POWERED BY KIGO · FEPRO 2026',
      style: TextStyle(color: KigoDesign.textTertiary, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.w500),
    );
  }
}
