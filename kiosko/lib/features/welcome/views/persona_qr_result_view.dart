import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/persona_qr_result_viewmodel.dart';

class PersonaQrResultView extends StatefulWidget {
  final PersonaQrResultViewModel viewModel;

  const PersonaQrResultView({super.key, required this.viewModel});

  @override
  State<PersonaQrResultView> createState() => _PersonaQrResultViewState();
}

class _PersonaQrResultViewState extends State<PersonaQrResultView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_updateView);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_updateView);
    super.dispose();
  }

  void _updateView() => setState(() {});

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
                  _buildHeader(),
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: KigoDesign.brand,
            borderRadius: BorderRadius.circular(KigoDesign.radius),
          ),
          child: const Center(
            child: Text('K', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kigo', style: TextStyle(color: KigoDesign.textPrimary, fontSize: 29, fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text('SELF CHECK-IN', style: TextStyle(color: KigoDesign.textSecondary, fontSize: 14, letterSpacing: 4, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (widget.viewModel.estado) {
      case PersonaQrResultEstado.cargando:
        return _buildCargando();
      case PersonaQrResultEstado.miembro:
        return _buildExitoso(titulo: 'Bienvenido a casa', subtitulo: null);
      case PersonaQrResultEstado.invitado:
        return _buildExitoso(titulo: '¡Acceso concedido!', subtitulo: 'Puedes ingresar al evento.\nBienvenido.');
      case PersonaQrResultEstado.desconocido:
        return _buildError(
          'Esta cuenta no tiene invitación ni membresía en este centro',
        );
      case PersonaQrResultEstado.error:
        return _buildError(widget.viewModel.errorMsg ?? 'No se pudo verificar el código QR');
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
          'Verificando tu código...',
          style: TextStyle(color: KigoDesign.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildExitoso({required String titulo, required String? subtitulo}) {
    final h = MediaQuery.sizeOf(context).height;
    final iconSize = (h * 0.14).clamp(70.0, 110.0);
    final gap = (h * 0.04).clamp(10.0, 36.0);
    return Column(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: KigoDesign.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: KigoDesign.success.withValues(alpha: 0.5), width: 2),
          ),
          child: Icon(Icons.check_rounded, color: KigoDesign.success, size: iconSize * 0.55),
        ),
        SizedBox(height: gap),
        Text(titulo, style: TextStyle(color: KigoDesign.textPrimary, fontSize: (h * 0.048).clamp(22.0, 38.0), fontWeight: FontWeight.w800)),
        SizedBox(height: gap * 0.4),
        if (widget.viewModel.nombre != null)
          Text(
            widget.viewModel.nombre!,
            style: const TextStyle(color: KigoDesign.success, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1),
          ),
        if (widget.viewModel.casaDestino != null && widget.viewModel.casaDestino!.isNotEmpty) ...[
          SizedBox(height: gap * 0.22),
          Text(
            widget.viewModel.casaDestino!,
            style: const TextStyle(color: KigoDesign.textSecondary, fontSize: 16, letterSpacing: 2),
          ),
        ],
        if (subtitulo != null) ...[
          SizedBox(height: gap),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(color: KigoDesign.textSecondary, fontSize: 17, height: 1.6),
          ),
        ],
      ],
    );
  }

  Widget _buildError(String mensaje) {
    final h = MediaQuery.sizeOf(context).height;
    final iconSize = (h * 0.14).clamp(70.0, 110.0);
    final gap = (h * 0.04).clamp(10.0, 36.0);
    return Column(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: KigoDesign.error.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: KigoDesign.error.withValues(alpha: 0.5), width: 2),
          ),
          child: Icon(Icons.close_rounded, color: KigoDesign.error, size: iconSize * 0.55),
        ),
        SizedBox(height: gap),
        Text('Acceso denegado', style: TextStyle(color: KigoDesign.textPrimary, fontSize: (h * 0.044).clamp(20.0, 34.0), fontWeight: FontWeight.w800)),
        SizedBox(height: gap * 0.4),
        Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(color: KigoDesign.error, fontSize: 16, height: 1.5),
        ),
        SizedBox(height: gap),
        GestureDetector(
          onTap: () => Navigator.pop(context),
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
