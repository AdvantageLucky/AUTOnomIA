/* PUNTO ÚNICO DE BIFURCACIÓN ENTRE EL FLUJO PEATONAL Y EL VEHICULAR */

import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/features/registro/views/touch_register_view.dart';
import 'package:kigo_kiosco/features/registro_vehicular/viewmodels/vehicular_register_viewmodel.dart';
import 'package:kigo_kiosco/features/registro_vehicular/views/vehicular_register_view.dart';

/// Decide qué flujo de registro monta el kiosko según su tipo.
///
/// La bifurcación vive aquí y no repartida por las vistas de bienvenida para
/// que agregar un tercer tipo de acceso, o cambiar la regla, sea un solo lugar.
/// El tipo lo manda el backend en la config del kiosko, así que el mismo APK
/// sirve para una caseta peatonal y para una vehicular: lo decide el admin
/// desde el dashboard, no el instalador.
abstract final class RegistroRouter {
  /// Flujo para quien llega sin invitación.
  static Widget paraVisitante(KioskoConfig config) {
    if (config.tipo != TipoKiosko.vehicular) return TouchRegisterView(config: config);

    return VehicularRegisterView(
      viewModel: VehicularRegisterViewModel(config),
    );
  }

  /// Flujo para quien ya escaneó su QR.
  ///
  /// [titular] y [casaDestino] salen de la invitación validada: al invitado no
  /// se le vuelve a preguntar a dónde va.
  static Widget paraInvitado(
    KioskoConfig config, {
    required String token,
    String? titular,
    String? casaDestino,
  }) {
    return VehicularRegisterView(
      viewModel: VehicularRegisterViewModel(
        config,
        tokenInvitacion: token,
        titular: titular,
        casaDestino: casaDestino,
      ),
    );
  }

  /// true si al invitado hay que pedirle alguna captura antes de dejarlo pasar.
  ///
  /// Cuando es false el QR basta por sí solo y el kiosko consume la invitación
  /// de inmediato, que es el comportamiento del flujo peatonal de siempre.
  static bool invitadoRequiereCapturas(KioskoConfig config) {
    return config.ineObligatorioInvitado ||
        config.fotoRostroInvitado ||
        config.fotoPlacaInvitado;
  }
}
