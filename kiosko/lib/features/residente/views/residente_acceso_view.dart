import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/resident_pin_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/resident_pin_view.dart';

class ResidenteAccesoView extends StatefulWidget {
  const ResidenteAccesoView({super.key});

  @override
  State<ResidenteAccesoView> createState() => _ResidenteAccesoViewState();
}

class _ResidenteAccesoViewState extends State<ResidenteAccesoView> {
  static const _storage = FlutterSecureStorage();
  static const _keyConsentTs = 'cara_consent_ts';

  bool _consentDado = false;
  bool _verificandoConsent = true;

  @override
  void initState() {
    super.initState();
    _verificarConsent();
  }

  Future<void> _verificarConsent() async {
    final ts = await _storage.read(key: _keyConsentTs);
    if (mounted) {
      setState(() {
        _consentDado = ts != null;
        _verificandoConsent = false;
      });
      if (!_consentDado) _pedirConsent();
    }
  }

  Future<void> _pedirConsent() async {
    final aceptado = await _mostrarConsentimientoFacial(context);
    if (!mounted) return;
    if (aceptado) {
      await _storage.write(
        key: _keyConsentTs,
        value: DateTime.now().toIso8601String(),
      );
      setState(() => _consentDado = true);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _irAlPin() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResidentPinView(viewModel: ResidentPinViewModel()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_verificandoConsent) {
      return const Scaffold(
        backgroundColor: KigoDesign.bgDark,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF542F), strokeWidth: 2.5),
        ),
      );
    }

    return Scaffold(
      backgroundColor: KigoDesign.bgDark,
      body: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 48),
          child: Column(
            children: [
              _buildHeader(context),
              const Spacer(),
              _buildAreaFacial(),
              const SizedBox(height: 40),
              _buildPinFallback(),
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
              style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kigo', style: TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text('SELF CHECK-IN',
                style: TextStyle(color: KigoDesign.textSecondary, fontSize: 14, letterSpacing: 4, fontWeight: FontWeight.w500)),
          ],
        ),
        const Spacer(),
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _buildAreaFacial() {
    return Column(
      children: [
        const Text(
          'Mira a la cámara para identificarte',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'El sistema verificará tu identidad automáticamente',
          textAlign: TextAlign.center,
          style: TextStyle(color: KigoDesign.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 40),

        // Marco del área de cara
        Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: KigoDesign.surface2,
            border: Border.all(color: const Color(0xFFFF542F).withValues(alpha: 0.35), width: 2.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.face_outlined,
                size: 80,
                color: const Color(0xFFFF542F).withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reconocimiento facial\nen configuración',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: KigoDesign.textTertiary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text(
          'Próximamente disponible',
          style: TextStyle(
            color: KigoDesign.textTertiary,
            fontSize: 13,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPinFallback() {
    return Column(
      children: [
        const Text(
          'O bien,',
          style: TextStyle(color: KigoDesign.textTertiary, fontSize: 15),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _irAlPin,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFF542F).withValues(alpha: 0.5), width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.dialpad_rounded, color: Color(0xFFFF542F), size: 22),
                SizedBox(width: 10),
                Text(
                  'Acceder por PIN...',
                  style: TextStyle(
                    color: Color(0xFFFF542F),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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

/// Diálogo de consentimiento específico para reconocimiento facial en el kiosko.
Future<bool> _mostrarConsentimientoFacial(BuildContext context) async {
  final bool? aceptado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF211D1D),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 14),
      contentPadding: const EdgeInsets.fromLTRB(28, 0, 28, 22),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      title: const Row(
        children: [
          Icon(Icons.face_outlined, color: Color(0xFFFF542F), size: 36),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Aviso de privacidad',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: const Text(
        'Su rostro será capturado y comparado localmente contra los registros del '
        'edificio para verificar su identidad. No se transmiten datos biométricos '
        'a servidores externos. Si prefiere no usar reconocimiento facial, puede '
        'ingresar con su PIN.',
        style: TextStyle(color: Color(0xFFC5BFBF), fontSize: 18, height: 1.6),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Regresar',
              style: TextStyle(color: Color(0xFF999494), fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Aceptar',
              style: TextStyle(color: Color(0xFFFF542F), fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      ],
    ),
  );
  return aceptado ?? false;
}
