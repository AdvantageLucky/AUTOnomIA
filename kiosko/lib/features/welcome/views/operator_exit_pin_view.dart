import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/pantalla_adaptable.dart';
import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/services/modo_kiosko_servicio.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/operator_exit_viewmodel.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

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
      backgroundColor: context.kBg,
      body: PantallaAdaptable(
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
              color: KigoDesign.brand,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),

        const Spacer(),

        const Icon(Icons.lock_outline_rounded, color: KigoDesign.brand, size: 24),
        const SizedBox(width: 10),
        Text(
          AppLocalizations.t(context, 'modo_operador'),
          style: TextStyle(
            color: context.kTextPrimary,
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
        Text(
          AppLocalizations.t(context, 'ingresa_pin_salir_kiosko'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.kTextSecondary,
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
                color: lleno ? KigoDesign.brand : context.kSurface2,
                border: Border.all(
                  color: viewModel.pinIncorrecto
                      ? KigoDesign.brand
                      : context.kBorder,
                  width: 1.5,
                ),
              ),
            );
          }),
        ),

        if (viewModel.pinIncorrecto) ...[
          const SizedBox(height: 18),
          Text(
            AppLocalizations.t(context, 'pin_incorrecto_intenta_de_nuevo'),
            style: const TextStyle(
              color: KigoDesign.brand,
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
    const orange = KigoDesign.brand;
    const orangeLight = KigoDesign.brandHover;
    final gray = context.kSurface2;

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
            style: TextStyle(
              color: presionado ? Colors.white : context.kTextPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeclaBorrar() {
    const orange = KigoDesign.brand;
    final gray = context.kSurface2;

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
          color: presionado ? context.kTeclaPresionada : gray,
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
            color: presionado ? orange : context.kTextSecondary,
            size: 26,
          ),
        ),
      ),
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
