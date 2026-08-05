import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/step_indicator.dart';

class CasaDestinoView extends StatefulWidget {
  const CasaDestinoView({super.key});

  @override
  State<CasaDestinoView> createState() => _CasaDestinoViewState();
}

class _CasaDestinoViewState extends State<CasaDestinoView> {
  final KioskoServicio _kioskoServicio = KioskoServicio();
  List<Map<String, dynamic>>? _destinos;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDestinos();
  }

  Future<void> _cargarDestinos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final destinos = await _kioskoServicio.obtenerDestinos();
      if (!mounted) return;
      setState(() {
        _destinos = destinos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar la lista de casas. Verifica la conexión.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171313),
      appBar: AppBar(
        backgroundColor: const Color(0xFF171313),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(left: 42, right: 42, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepIndicator(currentStep: 3, totalSteps: 5),
              const SizedBox(height: 42),
              const Text(
                '¿A qué casa te diriges?',
                style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 32),
              _buildContenido(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContenido() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: Color(0xFFFF542F))),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.wifi_off_rounded, color: Color(0xFF8F8989), size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFC5BFBF), fontSize: 18),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _cargarDestinos,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF542F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Reintentar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
    }

    final destinos = _destinos ?? [];
    if (destinos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Text(
            'Todavía no hay casas registradas en este kiosko.\nAvisa a la administración.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF999494), fontSize: 18),
          ),
        ),
      );
    }

    return Column(
      children: destinos.map((d) => _buildCasaCard(d)).toList(),
    );
  }

  Widget _buildCasaCard(Map<String, dynamic> destino) {
    final nombre = destino['nombre'] as String? ?? 'Sin nombre';
    final titular = destino['titular'] as String? ?? '';

    return GestureDetector(
      onTap: () => Navigator.pop(context, nombre),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1B1B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF302A2A), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF3A2420),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.home_outlined, color: Color(0xFFFF542F), size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  if (titular.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      titular,
                      style: const TextStyle(color: Color(0xFF8F8989), fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8F8989), size: 28),
          ],
        ),
      ),
    );
  }
}
