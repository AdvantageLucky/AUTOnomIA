import 'package:flutter/material.dart';
import 'package:kigo_salida/core/theme/kigo_design.dart';
import 'captura_salida_view.dart';

/// Pantalla de reposo del kiosko de salida -- un solo botón. Mismo lenguaje
/// visual que la pantalla de bienvenida del kiosko principal (marca, radios,
/// tipografía), reducido a lo estrictamente necesario: "Fin" según el
/// alcance pedido, sin flujos de invitación, QR ni asistente.
class SalirView extends StatelessWidget {
  const SalirView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.kBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: context.kChipMarca,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: KigoDesign.brand, size: 56),
                ),
                const SizedBox(height: 32),
                Text(
                  'AUTOnomIA',
                  style: TextStyle(
                    color: context.kTextPrimary,
                    fontFamily: 'Unbounded',
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Toca el botón para registrar tu salida',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.kTextSecondary, fontSize: 16),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 96,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KigoDesign.brand,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(KigoDesign.radiusLg)),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CapturaSalidaView()),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, size: 30),
                        SizedBox(width: 14),
                        Text(
                          'SALIR',
                          style: TextStyle(fontFamily: 'Unbounded', fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
