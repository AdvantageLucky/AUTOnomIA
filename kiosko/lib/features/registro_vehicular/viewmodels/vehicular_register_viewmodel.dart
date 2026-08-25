/* VIEWMODEL PARA EL REGISTRO VEHICULAR */

import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/features/registro/models/touch_step_model.dart';
import 'package:kigo_kiosco/features/registro/models/user_registration_model.dart';
import 'package:kigo_kiosco/features/registro/services/detector_servicio.dart';
import 'package:kigo_kiosco/features/registro/services/face_detector_servicio.dart';
import 'package:kigo_kiosco/features/registro_vehicular/services/placa_lector_servicio.dart';

/// Identifica qué captura corresponde a cada paso, para que la vista no dependa
/// del índice: los pasos se arman según la config y el índice cambia. La
/// placa ya no es un paso — se lee sola en paralelo (ver [leerPlaca]).
enum PasoVehicular { ine, rostro }

class VehicularRegisterViewModel extends ChangeNotifier {
  final DetectorServicio _detectorServicio = DetectorServicio();
  final FaceDetectorServicio _faceDetectorServicio = FaceDetectorServicio();
  final PlacaLectorServicio _placaLectorServicio = MockPlacaLectorServicio();
  late final Future<String?> _lecturaPlaca;

  UserRegistrationModel registrationData = UserRegistrationModel();

  int currentStep = 0;

  /// Pasos activos de este kiosko. Se arman en el constructor porque el
  /// dashboard decide qué capturas son obligatorias; pedir una foto que el
  /// backend no exige alarga la fila en la caseta, y omitir una que sí exige
  /// hace que el registro se rechace con 400 al final del flujo.
  late final List<PasoVehicular> pasos;

  late final List<TouchStepModel> steps;

  /// true si este visitante necesita placa: siempre para quien no trae
  /// invitación (es su identificador principal, ADR-0024), o para un
  /// invitado si la config del kiosko lo pide.
  late final bool requierePlaca;

  /// [tokenInvitacion] llega cuando el visitante ya escaneó su QR: cambia qué
  /// capturas se piden y con qué endpoint se registra la visita. [titular] y
  /// [casaDestino] vienen de la invitación validada, así que a un invitado no se
  /// le vuelve a preguntar a dónde va.
  VehicularRegisterViewModel(
    KioskoConfig config, {
    String? tokenInvitacion,
    String? titular,
    String? casaDestino,
  }) {
    registrationData.tokenInvitacion = tokenInvitacion;
    registrationData.nombreCompleto = titular;
    registrationData.casaDestino = casaDestino;
    final invitado = registrationData.esInvitado;

    pasos = invitado
        ? [
            // Al invitado su QR ya lo identifica; lo demás depende de la config.
            if (config.ineObligatorioInvitado) PasoVehicular.ine,
            if (config.fotoRostroInvitado) PasoVehicular.rostro,
          ]
        : [
            // En un acceso vehicular no se pide INE: el conductor no baja del
            // coche. La placa la identifica en su lugar (ADR-0024), pero ya no
            // es un paso de la UI — se lee sola en paralelo, ver [leerPlaca].
            if (config.fotoRostroVisitante) PasoVehicular.rostro,
          ];

    steps = pasos.map(_descripcionDe).toList();

    requierePlaca = !invitado || config.fotoPlacaInvitado;

    // Arranca apenas se crea el viewmodel — en paralelo con INE/rostro, no
    // después. Para cuando el conductor termina esos pasos, la lectura ya
    // suele estar resuelta.
    _lecturaPlaca = requierePlaca ? _placaLectorServicio.leer() : Future.value(null);
  }

  /// Espera la lectura en paralelo que arrancó en el constructor. Si hubo
  /// lectura, la deja confirmada de una vez; si no y [requierePlaca], la
  /// vista debe ofrecer el teclado manual.
  Future<String?> leerPlaca() async {
    final placa = await _lecturaPlaca;
    if (placa != null) confirmarPlaca(placa);
    return placa;
  }

  // ── Estados de carga del procesamiento local ────────────────────────────────

  bool _isProcessingIne = false;
  bool get isProcessingIne => _isProcessingIne;

  bool _isProcessingRostro = false;
  bool get isProcessingRostro => _isProcessingRostro;

  bool get isProcessing => _isProcessingIne || _isProcessingRostro;

  // ── Navegación entre pasos ──────────────────────────────────────────────────

  PasoVehicular get pasoActual => pasos[currentStep];

  TouchStepModel get currentStepData => steps[currentStep];

  bool get isLastStep => currentStep == pasos.length - 1;

  /// El indicador visual suma los pasos de captura más el resumen. El invitado
  /// no elige casa destino: viene en su invitación.
  int get indicatorTotalSteps =>
      pasos.length + (registrationData.esInvitado ? 1 : 2);

  int get indicatorStep => currentStep;

  void nextStep() {
    if (currentStep < pasos.length - 1) {
      currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  // ── Procesamiento local (mismos servicios que el flujo peatonal) ────────────

  Future<bool> procesarEscaneoIne(String pathFoto) async {
    _isProcessingIne = true;
    notifyListeners();

    try {
      final datosExtraidos = await _detectorServicio.analizarIne(pathFoto);

      if (datosExtraidos?.curp == null) {
        debugPrint('La IA no detectó un INE válido en la imagen.');
        return false;
      }

      registrationData.curp = datosExtraidos!.curp;
      registrationData.nombreCompleto = datosExtraidos.nombreCompleto;
      registrationData.pathFotoIne = datosExtraidos.pathFotoIne;
      return true;
    } catch (e) {
      debugPrint('Error al procesar la INE: $e');
      return false;
    } finally {
      _isProcessingIne = false;
      notifyListeners();
    }
  }

  Future<bool> procesarEscaneoRostro(String pathFoto) async {
    _isProcessingRostro = true;
    notifyListeners();

    try {
      final esValido = await _faceDetectorServicio.tieneRostroValido(pathFoto);
      if (esValido) registrationData.pathFotoRostro = pathFoto;
      return esValido;
    } catch (e) {
      debugPrint('Error al procesar el rostro: $e');
      return false;
    } finally {
      _isProcessingRostro = false;
      notifyListeners();
    }
  }

  void confirmarPlaca(String placa) {
    registrationData.placa = placa;
    notifyListeners();
  }

  // ── Copys por paso ──────────────────────────────────────────────────────────

  TouchStepModel _descripcionDe(PasoVehicular paso) {
    switch (paso) {
      case PasoVehicular.ine:
        return TouchStepModel(
          title: 'Coloca tu identificación dentro del recuadro',
          subtitle: '',
          description:
              'Asegúrate de que tu INE esté bien iluminada, sin reflejos y completamente visible dentro del recuadro.',
          icon: Icons.badge_outlined,
          buttonTextKey: 'capturar_ine_button',
        );
      case PasoVehicular.rostro:
        return TouchStepModel(
          title: 'Coloca tu rostro dentro del recuadro',
          subtitle: '',
          description:
              'Puedes capturar una foto de tu rostro o usar evidencia desde cámaras conectadas al sistema de seguridad.',
          icon: Icons.photo_camera_outlined,
          buttonTextKey: 'reconocimiento_facial_button',
        );
    }
  }
}
