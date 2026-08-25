import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/features/activacion/models/device_solicitud.dart';
import 'package:kigo_kiosco/features/activacion/viewmodels/activacion_viewmodel.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
    _vm = ActivacionViewModel(KioskoServicio());
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
        return _buildCargando(AppLocalizations.t(context, 'activando_dispositivo'));
      case ActivacionEstado.esperando:
        return _buildEsperando();
      case ActivacionEstado.expirado:
        return _buildExpirado();
      case ActivacionEstado.error:
        return _buildError();
      case ActivacionEstado.aprobado:
        return _buildCargando(AppLocalizations.t(context, 'activacion_completada'));
    }
  }

  Widget _buildCargando(String mensaje) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: KigoDesign.brand, strokeWidth: 2.5),
        const SizedBox(height: 24),
        Text(mensaje, style: _estiloSubtitulo),
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
              Text(
                AppLocalizations.t(context, 'activar_dispositivo_title'),
                style: const TextStyle(color: KigoDesign.brand, fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.t(context, 'activar_dispositivo_subtitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: KigoDesign.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 40),
              if (isWide)
                _buildQrYCodigoHorizontal(solicitud, qrData)
              else
                _buildQrYCodigoVertical(solicitud, qrData),
              const SizedBox(height: 32),
              Text(solicitud.verificationUri,
                  style: const TextStyle(color: KigoDesign.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Text('${AppLocalizations.t(context, 'expira_en_prefix')} $countdown',
                  style: const TextStyle(color: KigoDesign.textSecondary, fontSize: 14)),
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
          const Expanded(child: Divider(color: KigoDesign.border, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(AppLocalizations.t(context, 'o_separador'), style: const TextStyle(color: KigoDesign.textTertiary, fontSize: 13)),
          ),
          const Expanded(child: Divider(color: KigoDesign.border, thickness: 1)),
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
        Container(width: 1, height: 55, color: KigoDesign.border),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(AppLocalizations.t(context, 'o_separador'), style: const TextStyle(color: KigoDesign.textTertiary, fontSize: 13)),
        ),
        Container(width: 1, height: 55, color: KigoDesign.border),
      ],
    );
  }

  Widget _buildCodigo(String userCode) {
    return Column(
      children: [
        Text(
          AppLocalizations.t(context, 'codigo_label'),
          style: const TextStyle(color: KigoDesign.textSecondary, fontSize: 13, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: KigoDesign.surface2,
            borderRadius: BorderRadius.circular(KigoDesign.radius),
            border: Border.all(color: KigoDesign.brand, width: 1.5),
          ),
          child: Text(
            userCode,
            style: const TextStyle(
              color: KigoDesign.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
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
        Text(
          AppLocalizations.t(context, 'codigo_expirado_title'),
          style: const TextStyle(color: KigoDesign.textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(AppLocalizations.t(context, 'codigo_expirado_subtitle'), style: const TextStyle(color: KigoDesign.textSecondary, fontSize: 15)),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _vm.iniciar,
          child: Text(AppLocalizations.t(context, 'solicitar_nuevo_codigo_button')),
        ),
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
          _vm.errorMsg ?? AppLocalizations.t(context, 'error_desconocido'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: KigoDesign.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _vm.iniciar,
          child: Text(AppLocalizations.t(context, 'retry_button_text')),
        ),
      ],
    );
  }

  static const _estiloSubtitulo = TextStyle(color: KigoDesign.textSecondary, fontSize: 16);
}
