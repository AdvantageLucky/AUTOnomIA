/* VISTA DE RESUMEN Y ESPERA DE APROBACIÓN (reemplaza a confirm_data_view.dart) */
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/registro/models/user_registration_model.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/step_indicator.dart';

class ResumenSolicitudView extends StatefulWidget {
  final UserRegistrationModel registrationData;

  const ResumenSolicitudView({super.key, required this.registrationData});

  @override
  State<ResumenSolicitudView> createState() => _ResumenSolicitudViewState();
}

class _ResumenSolicitudViewState extends State<ResumenSolicitudView> {
  late final KioskoServicio _kioskoServicio;
  Timer? _pollTimer;
  Timer? _regresoTimer;

  bool _isSubmitting = true;
  String? _submitError;
  String _estado = 'PENDIENTE';
  int? _visitaId;
  DateTime _horaSolicitud = DateTime.now();

  @override
  void initState() {
    super.initState();
    _kioskoServicio = context.read<KioskoServicio>();
    _registrarVisita();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _regresoTimer?.cancel();
    super.dispose();
  }

  Future<void> _registrarVisita() async {
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final data = widget.registrationData;

    if (data.curp == null ||
        data.curp!.length != 18 ||
        data.pathFotoIne == null) {
      setState(() {
        _isSubmitting = false;
        _submitError = 'Faltan datos del registro. Regresa e intenta de nuevo.';
      });
      return;
    }

    try {
      final respuesta = await _kioskoServicio.registrarVisitante(
        titular: data.nombreCompleto ?? 'Visitante',
        curp: data.curp!,
        motivoVisita: data.motivoVisita ?? 'No especificado',
        casaDestino: data.casaDestino ?? 'No especificado',
        pathFotoIne: data.pathFotoIne!,
        pathFotoRostro: data.pathFotoRostro,
      );

      if (!mounted) return;

      final creadoEn = DateTime.tryParse(respuesta['created_at'] as String? ?? '');

      setState(() {
        _visitaId = respuesta['id'] as int?;
        _estado = respuesta['estado'] as String? ?? 'PENDIENTE';
        _horaSolicitud = creadoEn ?? DateTime.now();
        _isSubmitting = false;
      });

      _iniciarPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = 'No se pudo registrar tu acceso. Intenta de nuevo.\n\nDetalle: $e';
      });
    }
  }

  void _iniciarPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _consultarEstado());
  }

  Future<void> _consultarEstado() async {
    if (!mounted || _visitaId == null) {
      _pollTimer?.cancel();
      return;
    }

    try {
      final respuesta = await _kioskoServicio.obtenerEstadoVisita(_visitaId!);
      if (!mounted) return;

      final nuevoEstado = respuesta['estado'] as String? ?? _estado;
      final yaEstabaEnRevision = _estado == 'REVISION';
      setState(() => _estado = nuevoEstado);

      if (nuevoEstado == 'APROBADO' || nuevoEstado == 'RECHAZADO' || nuevoEstado == 'REVISION') {
        _pollTimer?.cancel();
        // El kiosko se queda mostrando el resultado un minuto y regresa solo
        // a la bienvenida, para quedar listo para el siguiente visitante.
        _regresoTimer?.cancel();
        _regresoTimer = Timer(const Duration(minutes: 1), _regresarABienvenida);

        if (nuevoEstado == 'REVISION' && !yaEstabaEnRevision) {
          _mostrarDialogoRevision();
        }
      }
    } catch (e) {
      // Fallas transitorias de red durante el polling se ignoran: el siguiente
      // tick reintenta solo. Mostrar un error aquí cada 3s sería peor UX.
      debugPrint('Error consultando estado de visita: $e');
    }
  }

  bool get _esperandoAprobacion => _estado == 'PENDIENTE';

  void _regresarABienvenida() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _mostrarDialogoRevision() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF211D1D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: Color(0xFFFF542F), size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pasó a revisión manual',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'La solicitud pasó el tiempo límite de respuesta, tu solicitud pasó a '
          'revisión manual. Un vigilante te atenderá en breve.',
          style: TextStyle(color: Color(0xFFC5BFBF), fontSize: 18, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
    return Scaffold(
      backgroundColor: const Color(0xFF171313),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(left: 42, right: 42, top: 40, bottom: 40),
            child: Column(
              children: [
                const StepIndicator(currentStep: 4, totalSteps: 5),
                const SizedBox(height: 42),
                if (_submitError != null)
                  _buildErrorState()
                else ...[
                  _buildEstadoHeader(),
                  const SizedBox(height: 38),
                  _buildResumenCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFFF542F), size: 56),
        const SizedBox(height: 18),
        Text(
          _submitError!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFC5BFBF), fontSize: 18),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 68,
          child: ElevatedButton(
            onPressed: _registrarVisita,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF542F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text('Reintentar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoHeader() {
    if (_isSubmitting || _esperandoAprobacion) {
      return Column(
        children: [
          const SizedBox(
            width: 90,
            height: 90,
            child: LoadingIndicator(
              indicatorType: Indicator.circleStrokeSpin,
              colors: [Color(0xFFFF542F)],
              strokeWidth: 3,
              backgroundColor: Colors.transparent,
              pathBackgroundColor: Colors.transparent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isSubmitting ? 'Enviando tu solicitud…' : 'Esperando aprobación…',
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Un residente o administrador debe autorizar tu acceso',
            style: TextStyle(color: Color(0xFF999494), fontSize: 17, fontWeight: FontWeight.w400),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (_estado == 'REVISION') {
      return const Column(
        children: [
          Icon(Icons.hourglass_top_rounded, color: Color(0xFFFF542F), size: 80),
          SizedBox(height: 18),
          Text(
            'En revisión manual',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Un vigilante revisará tu acceso en breve',
            style: TextStyle(color: Color(0xFF999494), fontSize: 17, fontWeight: FontWeight.w400),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final aprobado = _estado == 'APROBADO';
    return Column(
      children: [
        Icon(
          aprobado ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
          color: aprobado ? const Color(0xFF4CAF50) : const Color(0xFFFF542F),
          size: 80,
        ),
        const SizedBox(height: 18),
        Text(
          aprobado ? '¡Acceso aprobado!' : 'Acceso no autorizado',
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResumenCard() {
    final data = widget.registrationData;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1B1B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF302A2A), width: 1.2),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: data.pathFotoRostro != null
                ? Image.file(
                    File(data.pathFotoRostro!),
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 140,
                    height: 140,
                    color: const Color(0xFF2B2727),
                    child: const Icon(Icons.person_outline, color: Color(0xFF8F8989), size: 56),
                  ),
          ),
          const SizedBox(height: 20),
          Text(
            data.nombreCompleto ?? 'Visitante',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildDato(Icons.access_time_rounded, 'Hora de solicitud',
              TimeOfDay.fromDateTime(_horaSolicitud).format(context)),
          _buildDato(Icons.flag_outlined, 'Motivo', data.motivoVisita ?? '—'),
          _buildDato(Icons.home_outlined, 'Casa destino', data.casaDestino ?? '—'),
        ],
      ),
    );
  }

  Widget _buildDato(IconData icon, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF542F), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF8F8989), fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(valor, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
