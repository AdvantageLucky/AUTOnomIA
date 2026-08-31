/* VIEWMODEL PARA LA PANTALLA DE REGISTRO TÁCTIL */

import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/core/services/evidencia_calidad_servicio.dart';
import 'package:kigo_kiosco/features/registro/models/paso_registro.dart';
import 'package:kigo_kiosco/features/registro/models/touch_step_model.dart';
import 'package:kigo_kiosco/features/registro/models/user_registration_model.dart';
import 'package:kigo_kiosco/features/registro/services/detector_servicio.dart';
import 'package:kigo_kiosco/features/registro/services/face_detector_servicio.dart';

class TouchRegisterViewModel extends ChangeNotifier {
  final KioskoConfig config;
  int currentStep = 0;
  final DetectorServicio _detectorServicio = DetectorServicio();
  final FaceDetectorServicio _faceDetectorServicio = FaceDetectorServicio();
  final EvidenciaCalidadServicio _calidadServicio = EvidenciaCalidadServicio();

  UserRegistrationModel registrationData = UserRegistrationModel();

  // estado de carga para el procesamiento local del OCR
  bool _isProcessingIne = false;
  bool get isProcessingIne => _isProcessingIne;

  // estado de carga para el procesamiento local del detector de rostro
  bool _isProcessingRostro = false;
  bool get isProcessingRostro => _isProcessingRostro;

  late final List<PasoRegistro> pasos;
  late final List<TouchStepModel> steps;

  TouchRegisterViewModel([KioskoConfig? config])
      : config = config ?? KioskoConfig.defaults {
    pasos = construirPasosOrdenados(
      orden: this.config.pasosSinInvitacion,
      habilitados: {
        if (this.config.fotoIneVisitante) PasoRegistro.ine,
        if (this.config.fotoRostroVisitante) PasoRegistro.rostro,
        // Quien llega sin invitación siempre tiene que decir a dónde va, así
        // que DESTINO no depende de un toggle. Lo que sí depende del
        // dashboard es en qué momento se le pregunta.
        PasoRegistro.destino,
      },
      // PLACA no entra aquí: este es el flujo peatonal y no hay lector de
      // placas que ejecutar. Si el dashboard lo trae en la lista se ignora
      // (lo atiende VehicularRegisterViewModel).
      fallback: const [PasoRegistro.rostro, PasoRegistro.destino],
    );
    steps = pasos.map(_stepModelPara).toList();
  }

  static TouchStepModel _stepModelPara(PasoRegistro p) {
    switch (p) {
      case PasoRegistro.ine:
        return TouchStepModel(
          title: 'Coloca tu identificación dentro del recuadro',
          subtitle: '',
          description:
              'Asegúrate de que tu INE esté bien iluminada, sin reflejos y completamente visible dentro del recuadro.',
          icon: Icons.badge_outlined,
          buttonTextKey: 'capturar_ine_button',
        );
      case PasoRegistro.rostro:
        return TouchStepModel(
          title: 'Coloca tu rostro dentro del recuadro',
          subtitle: '',
          description:
              'Puedes capturar una foto de tu rostro para verificar tu identidad.',
          icon: Icons.photo_camera_outlined,
          buttonTextKey: 'reconocimiento_facial_button',
        );
      // DESTINO y PLACA empujan su propia pantalla en cuanto les toca el
      // turno (ver esPasoAutomatico), así que este modelo casi no se alcanza
      // a ver -- existe para que steps quede 1:1 con pasos y el indicador de
      // progreso no se descuadre.
      case PasoRegistro.destino:
        return TouchStepModel(
          title: '¿A qué casa vas?',
          subtitle: '',
          description: 'Elige tu destino dentro del residencial.',
          icon: Icons.home_outlined,
          buttonTextKey: 'continue_button_text',
        );
      case PasoRegistro.placa:
        return TouchStepModel(
          title: 'Placa del vehículo',
          subtitle: '',
          description: 'Confirma la placa del vehículo.',
          icon: Icons.directions_car_outlined,
          buttonTextKey: 'continue_button_text',
        );
    }
  }

  PasoRegistro get pasoActual =>
      pasos.isNotEmpty ? pasos[currentStep] : PasoRegistro.rostro;

  TouchStepModel get currentStepData =>
      steps.isNotEmpty ? steps[currentStep] : _stepModelPara(PasoRegistro.rostro);

  bool get isLastStep => currentStep >= steps.length - 1;

  /// Los pasos configurados más el resumen. DESTINO ya es uno de los pasos,
  /// así que ya no se suma aparte como cuando estaba clavado al final.
  int get indicatorTotalSteps => steps.length + 1;
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

  Future<CalidadCaptura> procesarEscaneoIne(String pathFoto) async {
    _isProcessingIne = true;
    notifyListeners(); // Hace que la vista muestre un indicador de carga

    try {
      final datosExtraidos = await _detectorServicio.analizarIne(pathFoto);

      if (datosExtraidos == null || datosExtraidos.curp == null) {
        debugPrint("La IA no detectó un INE válido en la imagen.");
        _isProcessingIne = false;
        notifyListeners();
        return CalidadCaptura.noDetectado;
      }

      // El CURP se leyó bien, pero la foto en sí puede seguir borrosa -- se
      // pide de todos modos, no queda evidencia inservible en el registro.
      if (!await _calidadServicio.esNitida(pathFoto)) {
        _isProcessingIne = false;
        notifyListeners();
        return CalidadCaptura.borrosa;
      }

      // Guardamos de forma limpia los datos procesados en local en nuestro modelo
      registrationData.curp = datosExtraidos.curp;
      registrationData.nombreCompleto = datosExtraidos.nombreCompleto;
      registrationData.pathFotoIne = datosExtraidos.pathFotoIne;
      // La foto ya pasó el gate de nitidez -- se guarda también el número
      // crudo y la etiqueta derivada, para el dataset calificable.
      final varianza = await _calidadServicio.puntuarNitidez(pathFoto);
      if (varianza != null) {
        registrationData.nitidezIneScore = varianza;
        registrationData.calidadIne = _calidadServicio.calificar(varianza);
      }

      _isProcessingIne = false;
      notifyListeners();
      return CalidadCaptura.ok;
    } catch (e) {
      debugPrint("Error en el flujo del ViewModel al procesar la INE: $e");
      _isProcessingIne = false;
      notifyListeners();
      return CalidadCaptura.noDetectado;
    }
  }

  //LOGICA DE INTEGRACIÓN CON FACE_DETECTOR_SERVICIO

  Future<CalidadCaptura> procesarEscaneoRostro(String pathFoto) async {
    _isProcessingRostro = true;
    notifyListeners();

    try {
      final esValido = await _faceDetectorServicio.tieneRostroValido(pathFoto);
      if (!esValido) {
        _isProcessingRostro = false;
        notifyListeners();
        return CalidadCaptura.noDetectado;
      }

      if (!await _calidadServicio.esNitida(pathFoto)) {
        _isProcessingRostro = false;
        notifyListeners();
        return CalidadCaptura.borrosa;
      }

      registrationData.pathFotoRostro = pathFoto;
      _isProcessingRostro = false;
      notifyListeners();
      return CalidadCaptura.ok;
    } catch (e) {
      debugPrint("Error en el flujo del ViewModel al procesar el rostro: $e");
      _isProcessingRostro = false;
      notifyListeners();
      return CalidadCaptura.noDetectado;
    }
  }

  @override
  void dispose() {
    _faceDetectorServicio.dispose();
    super.dispose();
  }
}
