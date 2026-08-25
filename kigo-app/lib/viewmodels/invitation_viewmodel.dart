import 'package:flutter/foundation.dart';
import '../models/destino_model.dart';
import '../models/invitacion_model.dart';
import '../services/api_service.dart';

/// Invitaciones y destinos de la Persona autenticada — ver spec
/// 2026-08-17-kigo-app-rediseno-design.md.
class InvitationViewModel extends ChangeNotifier {
  List<InvitacionModel> _invitaciones = [];
  List<DestinoModel> _destinos = [];
  bool _isLoading = false;
  String? _error;

  List<InvitacionModel> get invitaciones => _invitaciones;
  List<DestinoModel> get destinos => _destinos;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  Future<void> crear({
    required int tenantId,
    required String telefono,
    required String nombre,
    required int destinoId,
    required bool permiteReconocimientoFacial,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiService().post(
        '/personas/me/invitaciones',
        {
          'tenant_id': tenantId,
          'telefono_invitado': telefono,
          'nombre_invitado': nombre,
          'tipo': 'PERSONAL',
          'destino_id': destinoId,
          'permite_reconocimiento_facial': permiteReconocimientoFacial,
        },
        auth: true,
      );
      _isLoading = false;
      notifyListeners();
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
