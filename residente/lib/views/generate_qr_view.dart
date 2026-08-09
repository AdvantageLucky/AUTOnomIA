import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/invitation_viewmodel.dart';
import '../models/invitation_model.dart';

class GenerateQrView extends StatefulWidget {
  const GenerateQrView({super.key});

  @override
  State<GenerateQrView> createState() => _GenerateQrViewState();
}

class _GenerateQrViewState extends State<GenerateQrView> {
  final _titularCtrl = TextEditingController();
  final _maxUsosCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _qrKey = GlobalKey();

  String _tipo = 'PERSONAL';
  // Por seguridad, la expiración por defecto es 24 horas.
  DateTime _expiresAt = DateTime.now().add(const Duration(hours: 24));
  bool _isLoading = false;
  bool _isSharing = false;
  InvitationModel? _creada;

  @override
  void dispose() {
    _titularCtrl.dispose();
    _maxUsosCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primaryOrange),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authVM = context.read<AuthViewModel>();
    final destinoId = authVM.destinoId;
    if (destinoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.t(context, 'no_destino_error')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final invVM = context.read<InvitationViewModel>();
    final inv = await invVM.createInvitation(
      titular: _titularCtrl.text.trim(),
      tipo: _tipo,
      destinoId: destinoId,
      maxUsos: _maxUsosCtrl.text.isEmpty ? null : int.tryParse(_maxUsosCtrl.text),
      expiresAt: _expiresAt,
    );
    setState(() {
      _isLoading = false;
      _creada = inv;
    });
    if (inv == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(invVM.error ?? AppLocalizations.t(context, 'create_error')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _shareQr() async {
    setState(() => _isSharing = true);
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final tmpDir = await getTemporaryDirectory();
      final file = File('${tmpDir.path}/kigo_invitacion.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      final titular = _creada?.titular ?? 'invitado';
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Tu pase de acceso Kigo para "$titular". Muestra este código QR al llegar.',
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.t(context, 'generate_qr_title')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: _creada != null ? _buildSuccess(isDark, textColor) : _buildForm(isDark, textColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool isDark, Color textColor) {
    final dateStr = '${_expiresAt.day}/${_expiresAt.month}/${_expiresAt.year}';
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          TextFormField(
            controller: _titularCtrl,
            style: TextStyle(color: textColor),
            textCapitalization: TextCapitalization.words,
            decoration: _inputDeco(
              label: AppLocalizations.t(context, 'visitor_name'),
              icon: Icons.person_outline,
              isDark: isDark,
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? AppLocalizations.t(context, 'required_field') : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _tipo,
            dropdownColor: isDark ? AppTheme.surfaceDark : Colors.white,
            style: TextStyle(color: textColor),
            decoration: _inputDeco(
              label: AppLocalizations.t(context, 'inv_type_label'),
              icon: Icons.group_outlined,
              isDark: isDark,
            ),
            items: [
              DropdownMenuItem(value: 'PERSONAL', child: Text(AppLocalizations.t(context, 'inv_personal_option'))),
              DropdownMenuItem(value: 'GRUPAL', child: Text(AppLocalizations.t(context, 'inv_grupal_option'))),
            ],
            onChanged: (v) => setState(() => _tipo = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _maxUsosCtrl,
            style: TextStyle(color: textColor),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDeco(
              label: AppLocalizations.t(context, 'max_uses_label'),
              icon: Icons.repeat_outlined,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: _inputDeco(
                label: AppLocalizations.t(context, 'expires_label'),
                icon: Icons.calendar_today_outlined,
                isDark: isDark,
              ),
              child: Text(dateStr, style: TextStyle(color: textColor)),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isLoading ? null : _submit,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Icon(Icons.qr_code_2, color: Colors.white),
            label: Text(
              AppLocalizations.t(context, 'generate_button'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(bool isDark, Color textColor) {
    final token = _creada!.token ?? '';
    return Column(
      children: [
        const Icon(Icons.check_circle_outline, color: AppTheme.primaryOrange, size: 56),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.t(context, 'inv_created_title'),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 4),
        Text(_creada!.titular, style: const TextStyle(color: AppTheme.textGrey)),
        const SizedBox(height: 24),
        if (token.isNotEmpty) ...[
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: token,
                version: QrVersions.auto,
                size: 220,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isSharing ? null : _shareQr,
            icon: _isSharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.share_rounded, color: Colors.white),
            label: Text(
              AppLocalizations.t(context, 'share_btn'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pushReplacementNamed(context, '/my_invitations'),
          child: Text(
            AppLocalizations.t(context, 'view_invitations_btn'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _creada = null),
          child: Text(AppLocalizations.t(context, 'create_another'), style: const TextStyle(color: AppTheme.primaryOrange)),
        ),
      ],
    );
  }

  InputDecoration _inputDeco({
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? AppTheme.textGrey : Colors.black54),
      floatingLabelStyle: const TextStyle(color: AppTheme.primaryOrange),
      prefixIcon: Icon(icon, color: AppTheme.primaryOrange),
      filled: true,
      fillColor: isDark ? AppTheme.surfaceDark : Colors.grey.shade100,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryOrange),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
