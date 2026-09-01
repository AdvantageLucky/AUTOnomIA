import 'package:flutter/foundation.dart';
import '../models/destino_model.dart';
import '../models/invitacion_model.dart';
import '../services/api_service.dart';

/// Invitaciones y destinos de la Persona autenticada — ver spec
/// 2026-08-17-kigo-app-rediseno-design.md.
class InvitationViewModel extends ChangeNotifier {
  List<InvitacionModel> _invitaciones = [];
  List<InvitacionRecibidaModel> _recibidas = [];
  List<DestinoModel> _destinos = [];
  bool _isLoading = false;
  bool _cargandoRecibidas = false;
  String? _error;

  List<InvitacionModel> get invitaciones => _invitaciones;
  List<InvitacionRecibidaModel> get recibidas => _recibidas;
  List<DestinoModel> get destinos => _destinos;
  bool get isLoading => _isLoading;
  bool get cargandoRecibidas => _cargandoRecibidas;
  String? get error => _error;

  Future<void> cargarRecibidas() async {
    _cargandoRecibidas = true;
    notifyListeners();
    try {
      final data = await ApiService().get('/personas/me/invitaciones/recibidas');
      final list = (data as List).cast<Map<String, dynamic>>();
      _recibidas = list.map(InvitacionRecibidaModel.fromJson).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _cargandoRecibidas = false;
      notifyListeners();
    }
  }

  Future<void> cargarDestinos(int tenantId) async {
    try {
      final data = await ApiService().get('/personas/me/destinos?tenant_id=$tenantId');
      final list = (data['destinos'] as List).cast<Map<String, dynamic>>();
      _destinos = list.map(DestinoModel.fromJson).toList();
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> cargarInvitaciones() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService().get('/personas/me/invitaciones');
      final list = (data as List).cast<Map<String, dynamic>>();
      _invitaciones = list.map(InvitacionModel.fromJson).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Devuelve el token de la invitación creada — se usa para armar el link
  /// compartible (ver AppConstants.serverOrigin + '/i/' + token).
  Future<String?> crear({
    required int tenantId,
    required String telefono,
    required String nombre,
    required int destinoId,
    required bool permiteReconocimientoFacial,
    DateTime? expiraEl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService().post(
        '/personas/me/invitaciones',
        {
          'tenant_id': tenantId,
          'telefono_invitado': telefono,
          'nombre_invitado': nombre,
          'tipo': 'PERSONAL',
          'destino_id': destinoId,
          'permite_reconocimiento_facial': permiteReconocimientoFacial,
          if (expiraEl != null) 'expires_at': expiraEl.toUtc().toIso8601String(),
        },
        auth: true,
      );
      _isLoading = false;
      notifyListeners();
      return (data as Map<String, dynamic>)['token'] as String?;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = 'No se pudo conectar al servidor';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> revocar(int id) async {
    try {
      await ApiService().delete('/personas/me/invitaciones/$id');
      _invitaciones.removeWhere((i) => i.id == id);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }
}
