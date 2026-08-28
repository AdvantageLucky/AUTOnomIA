import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/pantalla_adaptable.dart';
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
    final vm = widget.viewModel;
    return Scaffold(
      backgroundColor: context.kBg,
      body: PantallaAdaptable(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 48),
        child: Column(
          children: [
            _buildHeader(context),

            const Spacer(),

            _buildDisplay(),

            const SizedBox(height: 36),

            if (vm.tieneColisionPin)
              _buildSeleccionCandidato()
            else ...[
              _buildKeypad(),
              const SizedBox(height: 28),
              _buildConfirmar(),
            ],

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
          style: TextStyle(
            color: context.kTextSecondary,
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
            color: context.kSurface2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isEmpty
                  ? context.kBorder
                  : KigoDesign.brand.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Text(
            isEmpty ? '—' : pin,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isEmpty ? context.kTextTertiary : context.kTextPrimary,
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
    const orange = KigoDesign.brand;
    const orangeLight = KigoDesign.brandHover;
    final gray = context.kSurface2;

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
              style: const TextStyle(color: KigoDesign.brand, fontSize: 16, fontWeight: FontWeight.w600),
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
              color: vm.puedeConfirmar ? KigoDesign.brand : context.kSurface2,
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
                        color: vm.puedeConfirmar ? Colors.white : context.kTextTertiary,
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

  Widget _buildSeleccionCandidato() {
    final vm = widget.viewModel;
    final candidatos = vm.candidatos ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.kSurface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KigoDesign.brand.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt_outlined, color: KigoDesign.brand, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Varios residentes comparten este PIN. Selecciona tu casa:',
                  style: TextStyle(
                    color: context.kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...candidatos.map((c) {
            final int personaId = c['persona_id'] as int? ?? 0;
            final String nombre = c['nombre'] as String? ?? '';
            final String casa = c['casa_destino'] as String? ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: vm.isCargando
                    ? null
                    : () async {
                        final ok = await vm.confirmar(personaId: personaId);
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
                      },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: context.kSurface1,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.kBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: KigoDesign.brand.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.home_outlined, color: KigoDesign.brand, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              casa.isEmpty ? 'Sin casa asignada' : casa,
                              style: TextStyle(
                                color: context.kTextPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (nombre.isNotEmpty)
                              Text(
                                nombre,
                                style: TextStyle(
                                  color: context.kTextSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: KigoDesign.brand),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          TextButton(
            onPressed: vm.isCargando ? null : () => vm.cancelarSeleccion(),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: context.kTextSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
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
