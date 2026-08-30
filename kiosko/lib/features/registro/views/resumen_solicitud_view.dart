/* VISTA DE RESUMEN Y ESPERA DE APROBACIÓN (reemplaza a confirm_data_view.dart) */
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/services/led_servicio.dart';
import 'package:kigo_kiosco/core/widgets/boton_asistente_flotante.dart';
import 'package:kigo_kiosco/core/widgets/etiqueta_asistente.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/registro/models/user_registration_model.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/step_indicator.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

class ResumenSolicitudView extends StatefulWidget {
  final UserRegistrationModel registrationData;

  /// El indicador de pasos se parametriza porque el flujo vehicular tiene más
  /// pasos que el peatonal y el resumen siempre es el último.
  final int totalSteps;

  const ResumenSolicitudView({
    super.key,
    required this.registrationData,
    this.totalSteps = 4,
  });

  @override
  State<ResumenSolicitudView> createState() => _ResumenSolicitudViewState();
}

class _ResumenSolicitudViewState extends State<ResumenSolicitudView> {
  late final KioskoServicio _kioskoServicio;
  Timer? _pollTimer;
  Timer? _regresoTimer;

  bool _isSubmitting = true;
  String? _submitError;
  // Cuando el dato faltante es el identificador (INE/placa), reintentar el
  // mismo POST siempre va a fallar igual -- registrationData no cambia solo.
  // El unico camino real es regresar y recapturar.
  bool _errorRequiereRegresar = false;
  String _estado = 'PENDIENTE';
  int? _visitaId;
  DateTime _horaSolicitud = DateTime.now();
  final _led = LedServicio();
  bool _ledDisparado = false;

  /// LED verde/rojo según el resultado — solo para los dos estados finales
  /// reales; "en revisión" no es ni aprobado ni rechazado, no prende nada.
  /// Se dispara una sola vez por pantalla.
  void _dispararLedSiCorresponde() {
    if (_ledDisparado) return;
    if (_estado == 'APROBADO') {
      _ledDisparado = true;
      _led.mostrarAprobado();
    } else if (_estado == 'RECHAZADO') {
      _ledDisparado = true;
      _led.mostrarRechazado();
    }
  }

  @override
  void initState() {
    super.initState();
    _kioskoServicio = context.read<KioskoServicio>();
    // _registrarVisita() puede resolver AppLocalizations.t(context, ...) de
    // forma sincrona (rama sin identificador, antes de cualquier await) — eso
    // dispara dependOnInheritedWidgetOfExactType antes de que initState()
    // termine. Se difiere al primer frame para evitarlo.
    WidgetsBinding.instance.addPostFrameCallback((_) => _registrarVisita());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _regresoTimer?.cancel();
    _led.apagar();
    super.dispose();
  }

  Future<void> _registrarVisita() async {
    setState(() {
      _isSubmitting = true;
      _submitError = null;
      _errorRequiereRegresar = false;
    });

    final data = widget.registrationData;

    // El invitado se identifica con el token del QR. Sin invitación hace falta
    // un identificador: INE en el flujo peatonal, placa en el vehicular.
    if (!data.esInvitado && !data.tieneIdentificador) {
      setState(() {
        _isSubmitting = false;
        _submitError = AppLocalizations.t(context, 'faltan_datos_registro');
        _errorRequiereRegresar = true;
      });
      return;
    }

    try {
      // El invitado consume su token: el backend crea la visita ya APROBADA con
      // las capturas que exija la config, así que no hay nada que esperar.
      if (data.esInvitado) {
        final respuesta = await _kioskoServicio.usarInvitacion(
          data.tokenInvitacion!,
          placa: data.placa ?? '',
          curp: data.curp,
          pathFotoIne: data.pathFotoIne,
          pathFotoRostro: data.pathFotoRostro,
          pathFotoPlaca: data.pathFotoPlaca,
        );

        if (!mounted) return;

        setState(() {
          _visitaId = respuesta['visita_id'] as int?;
          _estado = respuesta['estado'] as String? ?? 'APROBADO';
          _horaSolicitud = DateTime.now();
          _isSubmitting = false;
        });
        _dispararLedSiCorresponde();

        final config = context.read<KioskoConfigNotifier>().config;
        _regresoTimer?.cancel();
        _regresoTimer = Timer(Duration(seconds: config.tiempoExitoSeg), _regresarABienvenida);
        return;
      }

      final respuesta = await _kioskoServicio.registrarVisitante(
        // Sin nombre el backend usa la placa como titular, para que la visita
        // siga siendo buscable en la bitácora.
        titular: data.nombreCompleto ?? '',
        curp: data.curp ?? '',
        casaDestino:
            data.casaDestino ?? AppLocalizations.t(context, 'no_especificado'),
        placa: data.placa ?? '',
        pathFotoIne: data.pathFotoIne,
        pathFotoRostro: data.pathFotoRostro,
        pathFotoPlaca: data.pathFotoPlaca,
      );

      if (!mounted) return;

      final creadoEn = DateTime.tryParse(
        respuesta['created_at'] as String? ?? '',
      );

      setState(() {
        _visitaId = respuesta['id'] as int?;
        _estado = respuesta['estado'] as String? ?? 'PENDIENTE';
        _horaSolicitud = creadoEn ?? DateTime.now();
        _isSubmitting = false;
      });

      _iniciarPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError =
            '${AppLocalizations.t(context, 'no_se_pudo_registrar_prefix')} $e';
      });
    }
  }

  void _iniciarPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _consultarEstado(),
    );
  }

  Future<void> _consultarEstado() async {
    if (!mounted || _visitaId == null) {
      _pollTimer?.cancel();
      return;
    }

    try {
      final respuesta = await _kioskoServicio.obtenerEstadoVisita(_visitaId!);
      if (!mounted) return;

      final nuevoEstado = respuesta['estado'] as String? ?? _estado;
      final yaEstabaEnRevision = _estado == 'REVISION';
      setState(() => _estado = nuevoEstado);
      _dispararLedSiCorresponde();

      if (nuevoEstado == 'APROBADO' ||
          nuevoEstado == 'RECHAZADO' ||
          nuevoEstado == 'REVISION') {
        _pollTimer?.cancel();
        // El kiosko se queda mostrando el resultado brevemente y regresa solo
        // a la bienvenida, para quedar listo para el siguiente visitante.
        final config = context.read<KioskoConfigNotifier>().config;

        _regresoTimer?.cancel();
        _regresoTimer = Timer(Duration(seconds: config.tiempoExitoSeg), _regresarABienvenida);

        if (nuevoEstado == 'REVISION' && !yaEstabaEnRevision) {
          _mostrarDialogoRevision();
        }
      }
    } catch (e) {
      // Fallas transitorias de red durante el polling se ignoran: el siguiente
      // tick reintenta solo. Mostrar un error aquí cada 3s sería peor UX.
      debugPrint('Error consultando estado de visita: $e');
    }
  }

  bool get _esperandoAprobacion => _estado == 'PENDIENTE';

  void _regresarABienvenida() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _mostrarDialogoRevision() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: context.kSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.hourglass_top_rounded,
              color: KigoDesign.brand,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.t(context, 'revision_manual_dialog_title'),
                style: TextStyle(
                  color: context.kTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.t(context, 'revision_manual_dialog_content'),
          style: TextStyle(
            color: context.kTextSecondary,
            fontSize: 18,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.t(context, 'entendido_button'),
              style: const TextStyle(
                color: KigoDesign.brand,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: context.kBg,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 42,
                  right: 42,
                  top: 40,
                  bottom: 40,
                ),
                child: Column(
                  children: [
                    StepIndicator(
                      currentStep: widget.totalSteps - 1,
                      totalSteps: widget.totalSteps,
                    ),
                    const SizedBox(height: 42),
                    if (_submitError != null)
                      _buildErrorState()
                    else ...[
                      _buildEstadoHeader(),
                      const SizedBox(height: 38),
                      _buildResumenCard(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        BotonAsistenteFlotante(
          // Coincide con el padding real de esta pantalla (top: 40,
          // right: 42) -- esta pantalla SÍ usa SafeArea, igual que
          // WelcomeView/ConfirmarPlacaView.
          topDelBorde: 40,
          rightDelBorde: 42,
          onRespuestaLibre: (_) {},
          onCampoExtraido: (_) {},
        ),
        const Positioned(top: 40 + 50, right: 42, child: EtiquetaAsistente()),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: KigoDesign.brand,
          size: 56,
        ),
        const SizedBox(height: 18),
        Text(
          _submitError!,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.kTextSecondary, fontSize: 18),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 68,
          child: ElevatedButton(
            onPressed: _errorRequiereRegresar
                ? _regresarABienvenida
                : _registrarVisita,
            style: ElevatedButton.styleFrom(
              backgroundColor: KigoDesign.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              AppLocalizations.t(
                context,
                _errorRequiereRegresar
                    ? 'back_button_text'
                    : 'retry_button_text',
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoHeader() {
    if (_isSubmitting || _esperandoAprobacion) {
      return Column(
        children: [
          const SizedBox(
            width: 90,
            height: 90,
            child: LoadingIndicator(
              indicatorType: Indicator.circleStrokeSpin,
              colors: [KigoDesign.brand],
              strokeWidth: 3,
              backgroundColor: Colors.transparent,
              pathBackgroundColor: Colors.transparent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isSubmitting
                ? AppLocalizations.t(context, 'enviando_solicitud')
                : AppLocalizations.t(context, 'esperando_aprobacion'),
            style: TextStyle(
              color: context.kTextPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.t(context, 'esperando_aprobacion_subtitle'),
            style: TextStyle(
              color: context.kTextSecondary,
              fontSize: 17,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (_estado == 'REVISION') {
      return Column(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            color: KigoDesign.brand,
            size: 80,
          ),
          const SizedBox(height: 18),
          Text(
            AppLocalizations.t(context, 'en_revision_manual_title'),
            style: TextStyle(
              color: context.kTextPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.t(context, 'en_revision_manual_subtitle'),
            style: TextStyle(
              color: context.kTextSecondary,
              fontSize: 17,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final aprobado = _estado == 'APROBADO';
    return Column(
      children: [
        Icon(
          aprobado ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
          color: aprobado ? const Color(0xFF4CAF50) : KigoDesign.brand,
          size: 80,
        ),
        const SizedBox(height: 18),
        Text(
          aprobado
              ? AppLocalizations.t(context, 'acceso_aprobado')
              : AppLocalizations.t(context, 'acceso_no_autorizado'),
          style: TextStyle(
            color: context.kTextPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResumenCard() {
    final data = widget.registrationData;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.kSurfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.kBorder, width: 1.2),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: data.pathFotoRostro != null
                ? Image.file(
                    File(data.pathFotoRostro!),
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 140,
                    height: 140,
                    color: context.kSurface2,
                    child: Icon(
                      Icons.person_outline,
                      color: context.kTextSecondary,
                      size: 56,
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          Text(
            // Sin INE no hay nombre: se muestra la placa, que es como el
            // vigilante va a identificar esta visita.
            data.nombreCompleto ??
                data.placa ??
                AppLocalizations.t(context, 'visitante_label'),
            style: TextStyle(
              color: context.kTextPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildDato(
            Icons.access_time_rounded,
            AppLocalizations.t(context, 'hora_solicitud_label'),
            TimeOfDay.fromDateTime(_horaSolicitud).format(context),
          ),
          _buildDato(
            Icons.home_outlined,
            AppLocalizations.t(context, 'casa_destino_label'),
            data.casaDestino ?? '—',
          ),
          if (data.placa != null && data.placa!.isNotEmpty)
            _buildDato(
              Icons.directions_car_outlined,
              AppLocalizations.t(context, 'placa_label'),
              data.placa!,
            ),
        ],
      ),
    );
  }

  Widget _buildDato(IconData icon, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Icon(icon, color: KigoDesign.brand, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.kTextSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: TextStyle(
                    color: context.kTextPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
