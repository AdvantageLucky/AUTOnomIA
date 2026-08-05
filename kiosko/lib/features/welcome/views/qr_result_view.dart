import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/qr_result_viewmodel.dart';

class QrResultView extends StatefulWidget {
  final QrResultViewModel viewModel;

  const QrResultView({super.key, required this.viewModel});

  @override
  State<QrResultView> createState() => _QrResultViewState();
}

class _QrResultViewState extends State<QrResultView> {
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
      backgroundColor: const Color(0xFF171313),
      body: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 48),
          child: Column(
            children: [
              _buildHeader(),
              const Spacer(),
              _buildContent(),
              const Spacer(),
              _buildFooter(),
            ],
          ),
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
            child: Text('K', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kigo', style: TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text('SELF CHECK-IN', style: TextStyle(color: Color(0xFF8A8585), fontSize: 14, letterSpacing: 4, fontWeight: FontWeight.w500)),
          ],
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
    return const Column(
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(color: Color(0xFFFF542F), strokeWidth: 3),
        ),
        SizedBox(height: 36),
        Text(
          'Verificando invitación...',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildExitoso() {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.5), width: 2),
          ),
          child: const Icon(Icons.check_rounded, color: Color(0xFF22C55E), size: 60),
        ),
        const SizedBox(height: 36),
        const Text('¡Acceso concedido!', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        if (widget.viewModel.titular != null)
          Text(
            widget.viewModel.titular!,
            style: const TextStyle(color: Color(0xFF22C55E), fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1),
          ),
        if (widget.viewModel.casaDestino != null && widget.viewModel.casaDestino!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.viewModel.casaDestino!,
            style: const TextStyle(color: Color(0xFF8A8585), fontSize: 16, letterSpacing: 2),
          ),
        ],
        const SizedBox(height: 40),
        const Text(
          'Puedes ingresar al evento.\nBienvenido.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF8A8585), fontSize: 17, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5), width: 2),
          ),
          child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 60),
        ),
        const SizedBox(height: 36),
        const Text('Acceso denegado', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Text(
          widget.viewModel.errorMsg ?? 'La invitación no es válida',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2B2727),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF3D3838)),
            ),
            child: const Text('Volver a intentar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return const Text(
      'POWERED BY KIGO · FEPRO 2026',
      style: TextStyle(color: Color(0xFF595252), fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.w500),
    );
  }
}
