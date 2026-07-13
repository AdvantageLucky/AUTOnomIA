/* VISTA DE CONFIRMACIÓN DE DATOS */

import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/step_indicator.dart';
import 'package:kigo_kiosco/features/registro/models/user_registration_model.dart';
import 'package:kigo_kiosco/core/services/kiosko_servicio.dart';

class ConfirmDataView extends StatefulWidget {
  final UserRegistrationModel registrationData;

  const ConfirmDataView({super.key, required this.registrationData});

  @override
  State<ConfirmDataView> createState() => _ConfirmDataViewState();
}

class _ConfirmDataViewState extends State<ConfirmDataView> {
  final KioskoServicio _kioskoServicio = KioskoServicio();
  bool _isLoading = false;

  Future<void> _solicitarAcceso() async {
    final data = widget.registrationData;

    if (data.curp == null || data.curp!.length != 18) {
      _mostrarError('CURP no válida. Regresa y vuelve a escanear tu INE.');
      return;
    }
    // La clave de elector está en el reverso del INE — si no se detectó, usamos placeholder
    final claveElector = (data.claveElector != null && data.claveElector!.isNotEmpty)
        ? data.claveElector!
        : 'NO_DISPONIBLE';
    if (data.pathFotoIne == null || data.pathFotoRostro == null) {
      _mostrarError('Faltan fotos del registro. Regresa e intenta de nuevo.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _kioskoServicio.registrarVisitante(
        nombre: data.nombreCompleto ?? 'Visitante',
        claveElector: claveElector,
        curp: data.curp!,
        pathFotoIne: data.pathFotoIne!,
        pathFotoRostro: data.pathFotoRostro!,
      );

      if (!mounted) return;
      _mostrarExito();
    } catch (e) {
      if (!mounted) return;
      _mostrarError('No se pudo registrar tu acceso. Intenta de nuevo.\n\nDetalle: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1F1B1B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 28),
            SizedBox(width: 12),
            Text('¡Acceso registrado!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Tu visita fue registrada correctamente. Puedes ingresar.',
          style: TextStyle(color: Color(0xFFC5BFBF), fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text(
              'Finalizar',
              style: TextStyle(color: Color(0xFFFF542F), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF211D1D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Color(0xFFFF542F), size: 28),
            SizedBox(width: 12),
            Text('Error', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          mensaje,
          style: const TextStyle(color: Color(0xFFC5BFBF), fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(color: Color(0xFFFF542F), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombreCompleto = widget.registrationData.nombreCompleto;

    return Scaffold(
      backgroundColor: const Color(0xFF171313),
      body: SizedBox.expand(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 42,
              right: 42,
              top: 60,
              bottom: 40,
            ),
            child: Column(
              children: [
                _buildHeader(),

                const SizedBox(height: 50),

                const StepIndicator(
                  currentStep: 2,
                  totalSteps: 3,
                ),

                const SizedBox(height: 54),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Confirma tus datos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 39,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Verifica que la información sea correcta',
                    style: TextStyle(
                      color: Color(0xFF999494),
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

                const SizedBox(height: 42),

                _buildUserCard(nombreCompleto),

                const SizedBox(height: 38),

                _buildAccessButton(),

                const SizedBox(height: 48),

                const Text(
                  'POWERED BY KIGO · FEPRO 2026',
                  style: TextStyle(
                    color: Color(0xFF595252),
                    fontSize: 14,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFFF542F),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text(
              'K',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        const Text(
          'Kigo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(String? nombreCompleto) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1F1B1B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF302A2A),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  nombreCompleto ?? 'Visitante',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  nombreCompleto != null ? 'BIENVENIDO' : 'ID no disponible',
                  style: const TextStyle(
                    color: Color(0xFF999494),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B2727),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: const Color(0xFFFF542F),
                          width: 2.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      width: 96,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B2727),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        color: Color(0xFFFF542F),
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFF302A2A)),
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                _buildDataRow('Tipo', 'Visitante'),
                const SizedBox(height: 22),
                _buildDataRow('Método', 'Touch'),
                const SizedBox(height: 22),
                _buildDataRow(
                  'Validación IA',
                  'Pendiente',
                  valueColor: const Color(0xFFD6C21F),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {Color valueColor = Colors.white}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8F8989),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildAccessButton() {
    return SizedBox(
      width: double.infinity,
      height: 76,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _solicitarAcceso,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF542F),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF6B3020),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Solicitar acceso',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}
