/* VIEWMODEL PARA EL REGISTRO VEHICULAR */

import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/features/registro/models/touch_step_model.dart';
import 'package:kigo_kiosco/features/registro/models/user_registration_model.dart';
import 'package:kigo_kiosco/features/registro/services/detector_servicio.dart';
import 'package:kigo_kiosco/features/registro/services/face_detector_servicio.dart';
import 'package:kigo_kiosco/features/registro_vehicular/services/placa_detector_servicio.dart';

/// Identifica qué captura corresponde a cada paso, para que la vista no dependa
/// del índice: los pasos se arman según la config y el índice cambia.
enum PasoVehicular { ine, rostro, placa }

class VehicularRegisterViewModel extends ChangeNotifier {
  final DetectorServicio _detectorServicio = DetectorServicio();
  final FaceDetectorServicio _faceDetectorServicio = FaceDetectorServicio();
  final PlacaDetectorServicio _placaDetectorServicio = PlacaDetectorServicio();

  UserRegistrationModel registrationData = UserRegistrationModel();

  int currentStep = 0;

  /// Pasos activos de este kiosko. Se arman en el constructor porque el
  /// dashboard decide qué capturas son obligatorias; pedir una foto que el
  /// backend no exige alarga la fila en la caseta, y omitir una que sí exige
  /// hace que el registro se rechace con 400 al final del flujo.
  late final List<PasoVehicular> pasos;

  late final List<TouchStepModel> steps;

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
            if (config.fotoPlacaInvitado) PasoVehicular.placa,
          ]
        : [
            // En un acceso vehicular no se pide INE: el conductor no baja del
            // coche. La placa toma su lugar como identificador de la visita, así
            // que va primero y no es opcional (ADR-0024).
            PasoVehicular.placa,
            if (config.fotoRostroVisitante) PasoVehicular.rostro,
          ];

    steps = pasos.map(_descripcionDe).toList();
  }

  // ── Estados de carga del procesamiento local ────────────────────────────────

  bool _isProcessingIne = false;
  bool get isProcessingIne => _isProcessingIne;

  bool _isProcessingRostro = false;
  bool get isProcessingRostro => _isProcessingRostro;

  bool _isProcessingPlaca = false;
  bool get isProcessingPlaca => _isProcessingPlaca;

  bool get isProcessing =>
      _isProcessingIne || _isProcessingRostro || _isProcessingPlaca;

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

  /// Corre el OCR sobre la foto de la placa. Devuelve el texto leído o null si
  /// no se reconoció: la foto se conserva de todos modos porque la bitácora la
  /// exige aunque el visitante termine escribiendo la placa a mano.
  Future<String?> procesarEscaneoPlaca(String pathFoto) async {
    _isProcessingPlaca = true;
    notifyListeners();

    try {
      final detectada = await _placaDetectorServicio.analizarPlaca(pathFoto);
      registrationData.pathFotoPlaca = detectada.pathFoto;
      return detectada.texto;
    } catch (e) {
      debugPrint('Error al procesar la placa: $e');
      registrationData.pathFotoPlaca = pathFoto;
      return null;
    } finally {
      _isProcessingPlaca = false;
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
          buttonText: 'Capturar INE',
        );
      case PasoVehicular.rostro:
        return TouchStepModel(
          title: 'Coloca tu rostro dentro del recuadro',
          subtitle: '',
          description:
              'Puedes capturar una foto de tu rostro o usar evidencia desde cámaras conectadas al sistema de seguridad.',
          icon: Icons.photo_camera_outlined,
          buttonText: 'Reconocimiento Facial',
        );
      case PasoVehicular.placa:
        return TouchStepModel(
          title: 'Encuadra la placa de tu vehículo',
          subtitle: '',
          description:
              'Baja la ventanilla si es necesario y apunta la cámara a la placa delantera. Podrás corregir el texto si la lectura no es exacta.',
          icon: Icons.directions_car_outlined,
          buttonText: 'Capturar placa',
        );
    }
  }
}
