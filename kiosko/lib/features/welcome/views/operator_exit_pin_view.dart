import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/services/modo_kiosko_servicio.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/operator_exit_viewmodel.dart';

class OperatorExitPinView extends StatefulWidget {
  final OperatorExitViewModel viewModel;

  const OperatorExitPinView({super.key, required this.viewModel});

  @override
  State<OperatorExitPinView> createState() => _OperatorExitPinViewState();
}

class _OperatorExitPinViewState extends State<OperatorExitPinView> {
  final ModoKioskoServicio _modoKioskoServicio = ModoKioskoServicio();
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

  Future<void> _procesarDigito(String digit) async {
    final viewModel = widget.viewModel;
    viewModel.addDigit(digit);

    if (!viewModel.isComplete) return;

    if (viewModel.esCorrecto) {
      await _modoKioskoServicio.salirDeModoKiosko();
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      viewModel.marcarIncorrecto();
    }
  }

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

              _buildDisplay(),

              const SizedBox(height: 48),

              _buildKeypad(),

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

        const Icon(Icons.lock_outline_rounded, color: Color(0xFFFF542F), size: 24),
        const SizedBox(width: 10),
        const Text(
          'MODO OPERADOR',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),

        const Spacer(),

        const SizedBox(width: 44),
      ],
    );
  }

  Widget _buildDisplay() {
    final viewModel = widget.viewModel;
    final pin = viewModel.pin;

    return Column(
      children: [
        const Text(
          'Ingresa el PIN para salir del modo kiosko',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF8A8585),
            fontSize: 16,
            letterSpacing: 1,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(OperatorExitViewModel.maxLength, (i) {
            final lleno = i < pin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lleno ? const Color(0xFFFF542F) : const Color(0xFF2B2727),
                border: Border.all(
                  color: viewModel.pinIncorrecto
                      ? const Color(0xFFFF542F)
                      : const Color(0xFF3D3838),
                  width: 1.5,
                ),
              ),
            );
          }),
        ),

        if (viewModel.pinIncorrecto) ...[
          const SizedBox(height: 18),
          const Text(
            'PIN incorrecto, intenta de nuevo',
            style: TextStyle(
              color: Color(0xFFFF542F),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildKeypad() {
    const digits = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      children: [
        ...digits.map((row) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: row
                    .map((d) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            child: _buildTecla(d),
                          ),
                        ))
                    .toList(),
              ),
            )),

        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: _buildTeclaBorrar(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: _buildTecla('0'),
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildTecla(String digit) {
    const orange = Color(0xFFFF542F);
    const orangeLight = Color(0xFFFF714D);
    const gray = Color(0xFF2B2727);

    final bool presionado = _presionadoId == digit;

    return GestureDetector(
      onTapDown: (_) => setState(() => _presionadoId = digit),
      onTapUp: (_) {
        setState(() => _presionadoId = null);
        _procesarDigito(digit);
      },
      onTapCancel: () => setState(() => _presionadoId = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        height: 72,
        decoration: BoxDecoration(
          color: presionado ? orangeLight : gray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: presionado ? orangeLight : orange.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeclaBorrar() {
    const orange = Color(0xFFFF542F);
    const gray = Color(0xFF2B2727);

    final bool presionado = _presionadoId == 'borrar';

    return GestureDetector(
      onTapDown: (_) => setState(() => _presionadoId = 'borrar'),
      onTapUp: (_) {
        setState(() => _presionadoId = null);
        widget.viewModel.removeLastDigit();
      },
      onTapCancel: () => setState(() => _presionadoId = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        height: 72,
        decoration: BoxDecoration(
          color: presionado ? const Color(0xFF3D2020) : gray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: presionado
                ? orange.withValues(alpha: 0.5)
                : orange.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            color: presionado ? orange : const Color(0xFF8A8585),
            size: 26,
          ),
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
