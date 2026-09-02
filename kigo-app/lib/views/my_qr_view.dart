import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/hazard_stripe.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/pending_visits_viewmodel.dart';

/// Pantalla Principal / Inicio de Kigo:
/// Gira alrededor del Código QR personal del residente y su PIN de acceso rápido,
/// con acceso directo a solicitudes pendientes y estado del fraccionamiento.
class MyQrView extends StatefulWidget {
  const MyQrView({super.key, this.onGoToSolicitudes});

  final VoidCallback? onGoToSolicitudes;

  @override
  State<MyQrView> createState() => _MyQrViewState();
}

class _MyQrViewState extends State<MyQrView> {
  String? _dato;
  String? _error;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await ApiService().get('/personas/me/qr');
      setState(() => _dato = '${data['persona_id']}:${data['firma']}');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.t(context, 'no_se_pudo_conectar'));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final pendingVM = context.watch<PendingVisitsViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final membresia = auth.centroActivo;
    final pin = membresia?.status == 'rechazado' ? '' : (membresia?.pin ?? '');
    final solicitudesPendientes = pendingVM.visitas.length;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              _cargar(),
              if (membresia?.tenantId != null)
                pendingVM.cargar(membresia!.tenantId),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // Encabezado con saludo y datos de residencia
              _buildHeader(context, auth, membresia, isDark),
              const SizedBox(height: 16),

              // Banner interactivo si hay solicitudes pendientes
              if (solicitudesPendientes > 0) ...[
                _buildSolicitudesBanner(context, solicitudesPendientes, isDark),
                const SizedBox(height: 16),
              ],

              // Contenedor principal del QR y PIN
              if (_cargando)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _buildErrorState(context)
              else
                _buildQrCard(context, pin, isDark, auth.nombre.isNotEmpty ? auth.nombre : AppLocalizations.t(context, 'residente_fallback'), membresia),

              const SizedBox(height: 20),

              // Texto explicativo de uso
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.textDimmed),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      AppLocalizations.t(context, 'muestra_codigo_o_pin'),
                      style: TextStyle(
                        color: isDark ? AppTheme.textGrey : AppTheme.textDimmed,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AuthViewModel auth,
    dynamic membresia,
    bool isDark,
  ) {
    final nombre = auth.nombre.isNotEmpty ? auth.nombre : AppLocalizations.t(context, 'residente_fallback');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
      ),
      child: Row(
        children: [
          // Avatar con iniciales
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryOrange, AppTheme.brandHover],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radius),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryOrange.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              nombre.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Texto de saludo y centro
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppLocalizations.t(context, 'saludo_hola')}$nombre',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                const SizedBox(height: 2),
                if (membresia != null)
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${membresia.centroNombre} · ${membresia.casaDestino}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.textGrey : AppTheme.textDimmed,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitudesBanner(BuildContext context, int count, bool isDark) {
    return InkWell(
      onTap: widget.onGoToSolicitudes,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.amber.withOpacity(isDark ? 0.15 : 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.amber.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications_active_rounded, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count ${AppLocalizations.t(context, count > 1 ? 'visitas_plural' : 'visita_singular')}'
                    ' ${AppLocalizations.t(context, 'esperando_autorizacion')}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Text(
                    AppLocalizations.t(context, 'toca_revisar_autorizar'),
                    style: const TextStyle(color: AppTheme.textDimmed, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.error),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.t(context, 'retry')),
          ),
        ],
      ),
    );
  }

  /// Trata el QR como una credencial física, no como un dato en una tarjeta
  /// genérica: cabecera oscura tipo gafete (con el mismo naranja de
  /// seguridad del resto del sistema), muesca de agujero de cordón y un
  /// doblez hazard-stripe en la esquina -- el mismo motivo que corre por el
  /// kiosko y el dashboard.
  Widget _buildQrCard(BuildContext context, String pin, bool isDark, String nombre, dynamic membresia) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBadgeHeader(nombre, membresia, isDark),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  child: Column(children: [_buildQrContenido(pin, isDark)]),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: ClipPath(
                clipper: _EsquinaTriangleClipper(),
                child: const SizedBox(width: 34, height: 34, child: HazardStripeBar(height: 34, borderRadius: BorderRadius.zero)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeHeader(String nombre, dynamic membresia, bool isDark) {
    final subtitulo = membresia != null
        ? '${membresia.centroNombre} · ${membresia.casaDestino}'
        : AppLocalizations.t(context, 'credencial_de_acceso');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 44, 22),
      decoration: BoxDecoration(color: isDark ? AppTheme.backgroundBlack : AppTheme.surface2Light),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.t(context, 'kigo_id_acceso_label'),
            style: const TextStyle(
              fontFamily: 'Unbounded',
              color: AppTheme.primaryOrange,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            nombre,
            style: TextStyle(
              fontFamily: 'Unbounded',
              color: isDark ? Colors.white : AppTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: TextStyle(color: isDark ? AppTheme.textGrey : AppTheme.textDimmed, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQrContenido(String pin, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tarjeta del QR en fondo blanco para lectura óptica impecable
        Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: QrImageView(
                data: _dato ?? '',
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0F1018),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0F1018),
                ),
              ),
            ),
          ),

          // Tarjeta del PIN si está disponible
        if (pin.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildCuadroPin(context, pin, isDark),
        ],
      ],
    );
  }

  Widget _buildCuadroPin(BuildContext context, String pin, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface2Dark : AppTheme.surface2Light,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.dialpad_rounded, color: AppTheme.primaryOrange, size: 20),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.t(context, 'pin_de_acceso'),
                style: TextStyle(
                  color: isDark ? AppTheme.textGrey : AppTheme.textDimmed,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                pin,
                style: AppTheme.mono(const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  color: AppTheme.primaryOrange,
                )),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                color: AppTheme.primaryOrange,
                tooltip: AppLocalizations.t(context, 'copiar_pin_tooltip'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: pin));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.t(context, 'pin_copiado')),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Recorta un triángulo en la esquina superior derecha -- el "doblez" de la
/// credencial donde se asoma la franja hazard-stripe.
class _EsquinaTriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
