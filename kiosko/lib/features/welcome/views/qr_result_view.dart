import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/qr_result_viewmodel.dart';

class QrResultView extends StatelessWidget {
  final QrResultViewModel viewModel;

  const QrResultView({super.key, required this.viewModel});

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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kigo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 29,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'SELF CHECK-IN',
              style: TextStyle(
                color: Color(0xFF8A8585),
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

  Widget _buildContent() {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: const Color(0xFF1A3A1A),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF4CAF50),
            size: 60,
          ),
        ),

        const SizedBox(height: 36),

        const Text(
          '¡Acceso concedido!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 14),

        const Text(
          'Invitación válida',
          style: TextStyle(
            color: Color(0xFF4CAF50),
            fontSize: 16,
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 48),

        const Text(
          'Puedes ingresar al evento.\nBienvenido.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF8A8585),
            fontSize: 17,
            height: 1.6,
          ),
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
