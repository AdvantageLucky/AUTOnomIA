import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/operator_exit_viewmodel.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

/// Hoja compacta para validar el PIN de operador sin salir del modo kiosko
/// -- a diferencia de OperatorExitPinView (pantalla completa, dispara
/// salirDeModoKiosko()), esta solo confirma "sí es el vigilante" y regresa
/// true/false. Reusa OperatorExitViewModel porque el PIN es el mismo, la
/// única diferencia es qué pasa después de acertarlo.
Future<bool> pedirPinOperador(BuildContext context) async {
  final resultado = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _PinOperadorSheet(),
  );
  return resultado ?? false;
}

class _PinOperadorSheet extends StatefulWidget {
  const _PinOperadorSheet();

  @override
  State<_PinOperadorSheet> createState() => _PinOperadorSheetState();
}

class _PinOperadorSheetState extends State<_PinOperadorSheet> {
  final _vm = OperatorExitViewModel();
  String? _presionadoId;

  void _procesarDigito(String digit) {
    _vm.addDigit(digit);
    setState(() {});
    if (!_vm.isComplete) return;
    if (_vm.esCorrecto) {
      Navigator.pop(context, true);
    } else {
      _vm.marcarIncorrecto();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.kSurface1,
          borderRadius: BorderRadius.circular(KigoDesign.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded, color: KigoDesign.brand, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.t(context, 'pin_operador_title'),
                    style: TextStyle(color: context.kTextPrimary, fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: Icon(Icons.close_rounded, color: context.kTextSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(OperatorExitViewModel.maxLength, (i) {
                final lleno = i < _vm.pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: lleno ? KigoDesign.brand : context.kSurface2,
                    border: Border.all(
                      color: _vm.pinIncorrecto ? KigoDesign.brand : context.kBorder,
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),
            if (_vm.pinIncorrecto) ...[
              const SizedBox(height: 10),
              Text(AppLocalizations.t(context, 'pin_incorrecto_texto'), style: const TextStyle(color: KigoDesign.brand, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 20),
            ...List.generate(3, (row) {
              const filas = [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: filas[row]
                      .map((d) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: _tecla(d),
                            ),
                          ))
                      .toList(),
                ),
              );
            }),
            Row(
              children: [
                Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: _teclaBorrar())),
                Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: _tecla('0'))),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tecla(String digit) {
    final presionado = _presionadoId == digit;
    return GestureDetector(
      onTapDown: (_) => setState(() => _presionadoId = digit),
      onTapUp: (_) {
        setState(() => _presionadoId = null);
        _procesarDigito(digit);
      },
      onTapCancel: () => setState(() => _presionadoId = null),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: presionado ? KigoDesign.brandHover : context.kSurface2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(digit, style: TextStyle(color: presionado ? Colors.white : context.kTextPrimary, fontSize: 22, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _teclaBorrar() {
    final presionado = _presionadoId == 'borrar';
    return GestureDetector(
      onTapDown: (_) => setState(() => _presionadoId = 'borrar'),
      onTapUp: (_) {
        setState(() => _presionadoId = null);
        _vm.removeLastDigit();
        setState(() {});
      },
      onTapCancel: () => setState(() => _presionadoId = null),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: presionado ? context.kTeclaPresionada : context.kSurface2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.backspace_outlined, color: presionado ? KigoDesign.brand : context.kTextSecondary, size: 22),
      ),
    );
  }
}
