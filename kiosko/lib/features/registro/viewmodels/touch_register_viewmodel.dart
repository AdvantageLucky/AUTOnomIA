/* VIEWMODEL PARA LA PANTALLA DE REGISTRO TÁCTIL */

import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/features/registro/models/touch_step_model.dart';
import 'package:kigo_kiosco/features/registro/models/user_registration_model.dart';
import 'package:kigo_kiosco/features/registro/services/detector_servicio.dart';
import 'package:kigo_kiosco/features/registro/services/face_detector_servicio.dart';

enum PasoTouch { ine, rostro }

class TouchRegisterViewModel extends ChangeNotifier {
  final KioskoConfig config;
  int currentStep = 0;
  final DetectorServicio _detectorServicio = DetectorServicio();
  final FaceDetectorServicio _faceDetectorServicio = FaceDetectorServicio();

  UserRegistrationModel registrationData = UserRegistrationModel();

  // estado de carga para el procesamiento local del OCR
  bool _isProcessingIne = false;
  bool get isProcessingIne => _isProcessingIne;

  // estado de carga para el procesamiento local del detector de rostro
  bool _isProcessingRostro = false;
  bool get isProcessingRostro => _isProcessingRostro;

  late final List<PasoTouch> pasos;
  late final List<TouchStepModel> steps;

  TouchRegisterViewModel([KioskoConfig? config])
      : config = config ?? KioskoConfig.defaults {
    final list = <PasoTouch>[];
    for (final p in this.config.pasosSinInvitacion) {
      if (p == 'INE' && this.config.fotoIneVisitante) list.add(PasoTouch.ine);
      if (p == 'ROSTRO' && this.config.fotoRostroVisitante) list.add(PasoTouch.rostro);
    }
    // Fallback si no hay ningún paso activo de captura previa
    if (list.isEmpty) {
      if (this.config.fotoRostroVisitante) list.add(PasoTouch.rostro);
    }
    pasos = list;
    steps = pasos.map(_stepModelPara).toList();
  }

  static TouchStepModel _stepModelPara(PasoTouch p) {
    switch (p) {
      case PasoTouch.ine:
        return TouchStepModel(
          title: 'Coloca tu identificación dentro del recuadro',
          subtitle: '',
          description:
              'Asegúrate de que tu INE esté bien iluminada, sin reflejos y completamente visible dentro del recuadro.',
          icon: Icons.badge_outlined,
          buttonTextKey: 'capturar_ine_button',
        );
      case PasoTouch.rostro:
        return TouchStepModel(
          title: 'Coloca tu rostro dentro del recuadro',
          subtitle: '',
          description:
              'Puedes capturar una foto de tu rostro para verificar tu identidad.',
          icon: Icons.photo_camera_outlined,
          buttonTextKey: 'reconocimiento_facial_button',
        );
    }
  }

  PasoTouch get pasoActual => pasos.isNotEmpty ? pasos[currentStep] : PasoTouch.rostro;

  TouchStepModel get currentStepData =>
      steps.isNotEmpty ? steps[currentStep] : _stepModelPara(PasoTouch.rostro);

  bool get isLastStep => currentStep >= steps.length - 1;

  // Pasos de capturas + Casa + Resumen
  int get indicatorTotalSteps => steps.length + 2;
  int get indicatorStep => currentStep;

  void nextStep() {
    if (currentStep < steps.length - 1) {
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

  //LOGICA DE INTEGRACIÓN CON DETECTOR_SERVICIO ---

  /// Proceso:
  /// - Recibe la ruta de la foto capturada por la cámara
  /// -activa el estado de carga
  /// - manda la imagen al motor local de IA
  /// - mapea los resultados y avanza el flujo.

  Future<bool> procesarEscaneoIne(String pathFoto) async {
    _isProcessingIne = true;
    notifyListeners(); // Hace que la vista muestre un indicador de carga

    try {
      final datosExtraidos = await _detectorServicio.analizarIne(pathFoto);

      if (datosExtraidos != null && datosExtraidos.curp != null) {
        // Guardamos de forma limpia los datos procesados en local en nuestro modelo
        registrationData.curp = datosExtraidos.curp;
        registrationData.nombreCompleto = datosExtraidos.nombreCompleto;
        registrationData.pathFotoIne = datosExtraidos.pathFotoIne;

        _isProcessingIne = false;
        notifyListeners();
        return true; // Todo bien

      } else {
        debugPrint("La IA no detectó un INE válido en la imagen.");
        _isProcessingIne = false;
        notifyListeners();
        return false; // No es un INE o no se pudo leer
      }
    } catch (e) {
      debugPrint("Error en el flujo del ViewModel al procesar la INE: $e");
      _isProcessingIne = false;
      notifyListeners();
      return false;
    } /*finally {
      _isProcessingIne = false;
      notifyListeners(); // Apaga el estado de carga en la interfaz
    }*/
  }

  //LOGICA DE INTEGRACIÓN CON FACE_DETECTOR_SERVICIO

  Future<bool> procesarEscaneoRostro(String pathFoto) async {
    _isProcessingRostro = true;
    notifyListeners();

    try {
      final esValido = await _faceDetectorServicio.tieneRostroValido(pathFoto);

      if (esValido) {
        registrationData.pathFotoRostro = pathFoto;
      }

      _isProcessingRostro = false;
      notifyListeners();
      return esValido;
    } catch (e) {
      debugPrint("Error en el flujo del ViewModel al procesar el rostro: $e");
      _isProcessingRostro = false;
      notifyListeners();
      return false;
    }
  }
}
