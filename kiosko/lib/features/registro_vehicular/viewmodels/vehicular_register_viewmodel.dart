/* VIEWMODEL PARA EL REGISTRO VEHICULAR */

import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/core/services/evidencia_calidad_servicio.dart';
import 'package:kigo_kiosco/features/registro/models/paso_registro.dart';
import 'package:kigo_kiosco/features/registro/models/touch_step_model.dart';
import 'package:kigo_kiosco/features/registro/models/user_registration_model.dart';
import 'package:kigo_kiosco/features/registro/services/detector_servicio.dart';
import 'package:kigo_kiosco/features/registro/services/face_detector_servicio.dart';
import 'package:kigo_kiosco/features/residente/services/reconocimiento_facial_servicio.dart';
import 'package:kigo_kiosco/features/registro_vehicular/services/placa_lector_servicio.dart';

class VehicularRegisterViewModel extends ChangeNotifier {
  final DetectorServicio _detectorServicio = DetectorServicio();
  final FaceDetectorServicio _faceDetectorServicio = FaceDetectorServicio();
  // Mismo MobileFaceNet que usa el acceso de residentes. La huella se
  // calcula aqui, on-device: al backend solo viaja el vector.
  final ReconocimientoFacialServicio _huellaFacialServicio = ReconocimientoFacialServicio();
  final EvidenciaCalidadServicio _calidadServicio = EvidenciaCalidadServicio();
  final PlacaLectorServicio _placaLectorServicio = MockPlacaLectorServicio();
  late final Future<String?> _lecturaPlaca;

  UserRegistrationModel registrationData = UserRegistrationModel();

  int currentStep = 0;

  /// Pasos activos de este kiosko, en el orden que armó el dashboard. Se
  /// arman en el constructor porque el dashboard decide qué capturas son
  /// obligatorias; pedir una foto que el backend no exige alarga la fila en
  /// la caseta, y omitir una que sí exige hace que el registro se rechace con
  /// 400 al final del flujo.
  late final List<PasoRegistro> pasos;

  late final List<TouchStepModel> steps;

  /// true si este visitante necesita placa: siempre para quien no trae
  /// invitación (es su identificador principal, ADR-0024), o para un
  /// invitado si la config del kiosko lo pide.
  late final bool requierePlaca;

  /// Si CasaDestinoView debe preguntar el motivo -- solo aplica a quien no
  /// trae invitación, pero como esta pantalla nunca se muestra a un
  /// invitado (ver `!invitado` en `habilitados` abajo), no hace falta
  /// distinguir aquí.
  late final bool motivoHabilitado;

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

    // El invitado también respeta el orden del dashboard, sólo cambia qué
    // pasos están habilitados: su QR ya lo identifica y su invitación ya trae
    // la casa destino. Antes su lista estaba escrita a mano (INE y luego
    // ROSTRO) y el orden configurado no lo tocaba.
    requierePlaca = !invitado || config.fotoPlacaInvitado;
    motivoHabilitado = config.motivoObligatorioVisitante;

    pasos = construirPasosOrdenados(
      orden: config.pasosSinInvitacion,
      habilitados: {
        if (invitado ? config.ineObligatorioInvitado : config.fotoIneVisitante)
          PasoRegistro.ine,
        if (invitado ? config.fotoRostroInvitado : config.fotoRostroVisitante)
          PasoRegistro.rostro,
        if (requierePlaca) PasoRegistro.placa,
        // Al invitado no se le pregunta a dónde va: viene en la invitación.
        if (!invitado) PasoRegistro.destino,
      },
      // Un invitado sin ninguna captura habilitada pasa sólo con su QR, así
      // que su fallback es vacío a propósito.
      fallback: invitado ? const [] : const [PasoRegistro.rostro, PasoRegistro.destino],
    );

    steps = pasos.map(_descripcionDe).toList();

    // Arranca apenas se crea el viewmodel — en paralelo con INE/rostro, no
    // después. Para cuando el conductor llega al paso de PLACA, la lectura ya
    // suele estar resuelta: el paso sólo la confirma.
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

  PasoRegistro get pasoActual => pasos[currentStep];

  TouchStepModel get currentStepData => steps[currentStep];

  bool get isLastStep => currentStep == pasos.length - 1;

  /// Los pasos configurados más el resumen. PLACA y DESTINO ya son pasos
  /// ordenables, así que ya no se suman aparte como cuando estaban clavados
  /// al final del flujo.
  int get indicatorTotalSteps => pasos.length + 1;

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

  Future<CalidadCaptura> procesarEscaneoIne(String pathFoto) async {
    _isProcessingIne = true;
    notifyListeners();

    try {
      final datosExtraidos = await _detectorServicio.analizarIne(pathFoto);

      if (datosExtraidos?.curp == null) {
        debugPrint('La IA no detectó un INE válido en la imagen.');
        return CalidadCaptura.noDetectado;
      }

      if (!await _calidadServicio.esNitida(pathFoto)) {
        return CalidadCaptura.borrosa;
      }

      registrationData.curp = datosExtraidos!.curp;
      registrationData.nombreCompleto = datosExtraidos.nombreCompleto;
      registrationData.pathFotoIne = datosExtraidos.pathFotoIne;
      // La foto ya pasó el gate de nitidez -- se guarda también el número
      // crudo y la etiqueta derivada, para el dataset calificable.
      final varianza = await _calidadServicio.puntuarNitidez(pathFoto);
      if (varianza != null) {
        registrationData.nitidezIneScore = varianza;
        registrationData.calidadIne = _calidadServicio.calificar(varianza);
      }
      return CalidadCaptura.ok;
    } catch (e) {
      debugPrint('Error al procesar la INE: $e');
      return CalidadCaptura.noDetectado;
    } finally {
      _isProcessingIne = false;
      notifyListeners();
    }
  }

  Future<CalidadCaptura> procesarEscaneoRostro(String pathFoto) async {
    _isProcessingRostro = true;
    notifyListeners();

    try {
      final esValido = await _faceDetectorServicio.tieneRostroValido(pathFoto);
      if (!esValido) return CalidadCaptura.noDetectado;

      if (!await _calidadServicio.esNitida(pathFoto)) {
        return CalidadCaptura.borrosa;
      }

      registrationData.pathFotoRostro = pathFoto;

      // La huella facial es lo que permite reconocer a este visitante en su
      // siguiente entrada cuando no hay INE ni placa. Si falla, la visita se
      // registra igual: es un identificador para despues, no un requisito
      // para dejar pasar ahora.
      registrationData.embeddingRostro =
          await _huellaFacialServicio.calcularEmbedding(pathFoto);

      return CalidadCaptura.ok;
    } catch (e) {
      debugPrint('Error al procesar el rostro: $e');
      return CalidadCaptura.noDetectado;
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

  TouchStepModel _descripcionDe(PasoRegistro paso) {
    switch (paso) {
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
              'Puedes capturar una foto de tu rostro o usar evidencia desde cámaras conectadas al sistema de seguridad.',
          icon: Icons.photo_camera_outlined,
          buttonTextKey: 'reconocimiento_facial_button',
        );
      // PLACA y DESTINO se resuelven solos al llegarles el turno (ver
      // esPasoAutomatico), asi que estos copys casi no se alcanzan a ver --
      // existen para que steps quede 1:1 con pasos y el indicador de progreso
      // no se descuadre.
      case PasoRegistro.placa:
        return TouchStepModel(
          title: 'Placa del vehículo',
          subtitle: '',
          description: 'Confirma la placa del vehículo.',
          icon: Icons.directions_car_outlined,
          buttonTextKey: 'continue_button_text',
        );
      case PasoRegistro.destino:
        return TouchStepModel(
          title: '¿A qué casa vas?',
          subtitle: '',
          description: 'Elige tu destino dentro del residencial.',
          icon: Icons.home_outlined,
          buttonTextKey: 'continue_button_text',
        );
    }
  }


  @override
  void dispose() {
    _faceDetectorServicio.dispose();
    _huellaFacialServicio.dispose();
    super.dispose();
  }
}
