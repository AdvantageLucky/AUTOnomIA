/* VIEWMODEL PARA LA PANTALLA DE REGISTRO TÁCTIL */

import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/registro/models/touch_step_model.dart';
import 'package:kigo_kiosco/features/registro/models/user_registration_model.dart';
import 'package:kigo_kiosco/features/registro/services/detector_servicio.dart';
import 'package:kigo_kiosco/features/registro/services/face_detector_servicio.dart';

class TouchRegisterViewModel extends ChangeNotifier {
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

  final List<TouchStepModel> steps = [
    TouchStepModel(
      title: 'Captura tu INE',
      subtitle: 'Coloca tu identificación dentro del recuadro',
      description:
          'Asegúrate de que tu INE esté bien iluminada, sin reflejos y completamente visible dentro del recuadro.',
      icon: Icons.badge_outlined,
      buttonText: 'Capturar INE',
    ),
    TouchStepModel(
      title: 'Evidencia fotográfica',
      subtitle: 'Toma una fotografía de verificación',
      description:
          'Puedes capturar una foto de tu rostro o usar evidencia desde cámaras conectadas al sistema de seguridad.',
      icon: Icons.photo_camera_outlined,
      buttonText: 'Capturar fotografía',
    ),
  ];

  TouchStepModel get currentStepData => steps[currentStep];

  bool get isLastStep => currentStep == steps.length - 1;

  // El StepIndicator visual muestra los 3 pasos principales:
  // 0) INE  1) Rostro  2) Confirmación
  static const int indicatorTotalSteps = 3;
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

      if (datosExtraidos != null && (datosExtraidos.curp != null || datosExtraidos.claveElector != null)) {
        // Guardamos de forma limpia los datos procesados en local en nuestro modelo
        registrationData.curp = datosExtraidos.curp;
        registrationData.claveElector = datosExtraidos.claveElector;
        registrationData.nombreCompleto = datosExtraidos.nombreCompleto;
        registrationData.pathFotoIne = datosExtraidos.pathFotoIne;

        _isProcessingIne = false;
        notifyListeners();
        return true; // Todo bien

      } else {
        print("La IA no detectó un INE válido en la imagen.");
        _isProcessingIne = false;
        notifyListeners();
        return false; // No es un INE o no se pudo leer
      }
    } catch (e) {
      print("Error en el flujo del ViewModel al procesar la INE: $e");
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
      print("Error en el flujo del ViewModel al procesar el rostro: $e");
      _isProcessingRostro = false;
      notifyListeners();
      return false;
    }
  }
}
