import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/registro/views/touch_register_view.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/visitor_type_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/qr_scanner_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/qr_scanner_view.dart';

class VisitorTypeView extends StatefulWidget {
  final VisitorTypeViewModel viewModel;

  const VisitorTypeView({super.key, required this.viewModel});

  @override
  State<VisitorTypeView> createState() => _VisitorTypeViewState();
}

class _VisitorTypeViewState extends State<VisitorTypeView> {
  String? _presionadoId;

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
              _buildHeader(context),

              const Spacer(),

              const Text(
                '¿En que puedo ayudarte?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 56),

              _buildBotones(context),

              const Spacer(),

              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2B2727),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF8A8585),
              size: 18,
            ),
          ),
        ),

        const Spacer(),

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

        const Spacer(),

        const SizedBox(width: 44),
      ],
    );
  }

  Widget _buildBotones(BuildContext context) {
    final options = widget.viewModel.options;
    return Row(
      children: [
        Expanded(
          child: _buildBoton(
            context,
            id: options[0].id,
            icono: options[0].icon,
            label: options[0].title,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildBoton(
            context,
            id: options[1].id,
            icono: options[1].icon,
            label: options[1].title,
          ),
        ),
      ],
    );
  }

  Widget _buildBoton(
    BuildContext context, {
    required String id,
    required IconData icono,
    required String label,
  }) {
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
          if (id == 'tengo_invitacion') {
            navigator.push(MaterialPageRoute(
              builder: (_) => QrScannerView(
                viewModel: QrScannerViewModel(),
              ),
            ));
          } else {
            navigator.push(MaterialPageRoute(
              builder: (_) => const TouchRegisterView(),
            ));
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
            color: presionado ? orangeLight : orange.withValues(alpha: 0.25),
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
            Icon(
              icono,
              color: presionado ? Colors.white : orange,
              size: 72,
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: TextStyle(
                color: presionado ? Colors.white : const Color(0xFFD0CBCB),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
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
