import 'package:flutter/material.dart';
import 'package:kigo_salida/core/theme/kigo_design.dart';
import 'package:kigo_salida/features/activacion/models/device_solicitud.dart';
import 'package:kigo_salida/features/activacion/viewmodels/activacion_viewmodel.dart';
import 'package:kigo_salida/features/salida/services/salida_servicio.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Pantalla de activación (RFC 8628) -- mismo tratamiento visual que
/// kiosko/lib/features/activacion/views/activacion_view.dart, con texto
/// propio (sin l10n) y el nombre de este kiosko en vez del principal.
class ActivacionView extends StatefulWidget {
  final VoidCallback onActivado;

  const ActivacionView({super.key, required this.onActivado});

  @override
  State<ActivacionView> createState() => _ActivacionViewState();
}

class _ActivacionViewState extends State<ActivacionView> {
  late ActivacionViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ActivacionViewModel(SalidaServicio());
    _vm.addListener(_onVmChange);
    _vm.iniciar();
  }

  void _onVmChange() {
    if (_vm.estado == ActivacionEstado.aprobado) {
      widget.onActivado();
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChange);
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(child: _buildContenido()),
      ),
    );
  }

  Widget _buildContenido() {
    switch (_vm.estado) {
      case ActivacionEstado.solicitando:
        return _buildCargando('Activando dispositivo…');
      case ActivacionEstado.esperando:
        return _buildEsperando();
      case ActivacionEstado.expirado:
        return _buildExpirado();
      case ActivacionEstado.error:
        return _buildError();
      case ActivacionEstado.aprobado:
        return _buildCargando('Activación completada');
    }
  }

  Widget _buildCargando(String mensaje) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: KigoDesign.brand, strokeWidth: 2.5),
        const SizedBox(height: 24),
        Text(mensaje, style: TextStyle(color: context.kTextSecondary, fontSize: 16)),
      ],
    );
  }

  Widget _buildEsperando() {
    final solicitud = _vm.solicitud!;
    final minutos = _vm.segundosRestantes ~/ 60;
    final segundos = _vm.segundosRestantes % 60;
    final countdown = '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
    final qrData = '${solicitud.verificationUri}?device=${solicitud.userCode}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 560;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Activar kiosko de salida',
                style: TextStyle(color: KigoDesign.brand, fontFamily: 'Unbounded', fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'Escanea el código o introdúcelo en el dashboard para vincular este dispositivo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.kTextSecondary, fontSize: 16),
              ),
              const SizedBox(height: 40),
              if (isWide)
                _buildQrYCodigoHorizontal(solicitud, qrData)
              else
                _buildQrYCodigoVertical(solicitud, qrData),
              const SizedBox(height: 32),
              Text(solicitud.verificationUri, style: TextStyle(color: context.kTextSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Text('Expira en: $countdown', style: TextStyle(color: context.kTextSecondary, fontSize: 14)),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: KigoDesign.brand, strokeWidth: 2),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQrYCodigoHorizontal(DeviceSolicitud solicitud, String qrData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQr(qrData),
        const SizedBox(width: 32),
        _buildSeparadorO(),
        const SizedBox(width: 32),
        _buildCodigo(solicitud.userCode),
      ],
    );
  }

  Widget _buildQrYCodigoVertical(DeviceSolicitud solicitud, String qrData) {
    return Column(
      children: [
        _buildQr(qrData),
        const SizedBox(height: 28),
        Row(children: [
          Expanded(child: Divider(color: context.kBorder, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('o', style: TextStyle(color: context.kTextTertiary, fontSize: 13)),
          ),
          Expanded(child: Divider(color: context.kBorder, thickness: 1)),
        ]),
        const SizedBox(height: 28),
        _buildCodigo(solicitud.userCode),
      ],
    );
  }

  Widget _buildQr(String data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KigoDesign.radius),
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: 160,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSeparadorO() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 1, height: 55, color: context.kBorder),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('o', style: TextStyle(color: context.kTextTertiary, fontSize: 13)),
        ),
        Container(width: 1, height: 55, color: context.kBorder),
      ],
    );
  }

  Widget _buildCodigo(String userCode) {
    return Column(
      children: [
        Text('CÓDIGO', style: TextStyle(color: context.kTextSecondary, fontSize: 13, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: context.kSurface2,
            borderRadius: BorderRadius.circular(KigoDesign.radius),
            border: Border.all(color: KigoDesign.brand, width: 1.5),
          ),
          child: Text(
            userCode,
            style: TextStyle(
              color: context.kTextPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              fontFamily: 'JetBrains Mono',
              letterSpacing: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpirado() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Código expirado', style: TextStyle(color: context.kTextPrimary, fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Pide uno nuevo para seguir con la activación.', style: TextStyle(color: context.kTextSecondary, fontSize: 15)),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: _vm.iniciar, child: const Text('Solicitar nuevo código')),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: KigoDesign.brand, size: 56),
        const SizedBox(height: 16),
        Text(
          _vm.errorMsg ?? 'Ocurrió un error inesperado.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.kTextSecondary, fontSize: 15),
        ),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: _vm.iniciar, child: const Text('Reintentar')),
      ],
    );
  }
}
