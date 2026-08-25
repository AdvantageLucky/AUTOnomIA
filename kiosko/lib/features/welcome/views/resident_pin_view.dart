import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/resident_pin_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/resident_welcome_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/resident_welcome_view.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

class ResidentPinView extends StatefulWidget {
  final ResidentPinViewModel viewModel;

  const ResidentPinView({super.key, required this.viewModel});

  @override
  State<ResidentPinView> createState() => _ResidentPinViewState();
}

class _ResidentPinViewState extends State<ResidentPinView> {
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
      backgroundColor: KigoDesign.bgDark,
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

              const SizedBox(height: 28),

              _buildConfirmar(),

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
              color: KigoDesign.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: KigoDesign.textSecondary,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.t(context, 'kigo_label'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 29,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.t(context, 'self_checkin_label'),
              style: const TextStyle(
                color: KigoDesign.textSecondary,
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

  Widget _buildDisplay() {
    final pin = widget.viewModel.pin;
    final isEmpty = pin.isEmpty;

    return Column(
      children: [
        Text(
          AppLocalizations.t(context, 'ingresa_tu_numero'),
          style: const TextStyle(
            color: KigoDesign.textSecondary,
            fontSize: 16,
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 24),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          decoration: BoxDecoration(
            color: KigoDesign.surface2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isEmpty
                  ? const Color(0xFF3D3838)
                  : const Color(0xFFFF542F).withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Text(
            isEmpty ? '—' : pin,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isEmpty ? KigoDesign.textTertiary : Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
            ),
          ),
        ),
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
            // espacio espejo para alinear el 0 al centro
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildTecla(String digit) {
    const orange = Color(0xFFFF542F);
    const orangeLight = Color(0xFFFF714D);
    const gray = KigoDesign.surface2;

    final bool presionado = _presionadoId == digit;

    return GestureDetector(
      onTapDown: (_) => setState(() => _presionadoId = digit),
      onTapUp: (_) {
        setState(() => _presionadoId = null);
        widget.viewModel.addDigit(digit);
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
              color: presionado ? Colors.white : Colors.white,
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
    const gray = KigoDesign.surface2;

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
            color: presionado ? orange : KigoDesign.textSecondary,
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmar() {
    final vm = widget.viewModel;
    return Column(
      children: [
        if (vm.errorMsg != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              vm.errorMsg!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFF542F), fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        GestureDetector(
          onTap: vm.puedeConfirmar
              ? () async {
                  final ok = await vm.confirmar();
                  if (ok && mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResidentWelcomeView(
                          viewModel: ResidentWelcomeViewModel(
                            nombre: vm.nombreResidente ?? AppLocalizations.t(context, 'residente_label'),
                            casaDestino: vm.casaDestino ?? '',
                          ),
                        ),
                      ),
                    ).then((_) => vm.clear());
                  }
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              color: vm.puedeConfirmar ? const Color(0xFFFF542F) : KigoDesign.surface2,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: vm.isCargando
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      AppLocalizations.t(context, 'confirmar_button_caps'),
                      style: TextStyle(
                        color: vm.puedeConfirmar ? Colors.white : KigoDesign.textTertiary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Text(
      AppLocalizations.t(context, 'footer_text'),
      style: const TextStyle(
        color: KigoDesign.textTertiary,
        fontSize: 14,
        letterSpacing: 2,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
