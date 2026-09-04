import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kigo_kiosco/core/services/evidencia_seguridad_servicio.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';

enum QrResultEstado { cargando, exitoso, error }

class QrResultViewModel extends ChangeNotifier {
  final String token;

  QrResultEstado _estado = QrResultEstado.cargando;
  String? _titular;
  String? _casaDestino;
  String? _errorMsg;

  QrResultEstado get estado => _estado;
  String? get titular => _titular;
  String? get casaDestino => _casaDestino;
  String? get errorMsg => _errorMsg;

  QrResultViewModel({required this.token}) {
    _procesar();
  }

  Future<void> _procesar() async {
    try {
      final resultado = await KioskoServicio().usarInvitacion(token);
      _titular = resultado['titular'] as String?;
      _casaDestino = resultado['casa_destino'] as String?;
      _estado = QrResultEstado.exitoso;
    } catch (e) {
      _errorMsg = e.toString().replaceFirst('Exception: ', '');
      _estado = QrResultEstado.error;
      // Cualquier rechazo del backend al consumir la invitación (vencida,
      // revocada, ya agotada, token inexistente) cuenta como "QR inválido"
      // para la pestaña "Seguridad" -- a diferencia del PIN, aquí no hay un
      // solo mensaje de error a comparar, así que se reporta en todo el
      // catch en vez de filtrar por texto.
      unawaited(_reportarConEvidencia());
    }
    notifyListeners();
  }

  /// Toma la foto en segundo plano y recién entonces reporta -- el mobile_scanner
  /// ya soltó su cámara antes de llegar aquí (ver QrScannerView._onQrDetected),
  /// así que no compite por la lente con el escaneo del QR.
  Future<void> _reportarConEvidencia() async {
    final evidencia = await EvidenciaSeguridadServicio.capturar();
    await KioskoServicio().reportarEventoSeguridad(
      tipo: 'qr_invalido',
      detalle: _errorMsg,
      pathFoto: evidencia.pathFoto,
      embedding: evidencia.embedding,
    );
  }
}
