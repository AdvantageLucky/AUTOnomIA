import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _codigoCtrl = TextEditingController();
  final _casaDestinoCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _casaDestinoCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthViewModel>().login(
          _codigoCtrl.text.trim(),
          _casaDestinoCtrl.text.trim(),
          _pinCtrl.text.trim(),
        );
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
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
      fillColor: isDark ? AppTheme.surfaceDark : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? AppTheme.textGrey : Colors.black26),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner, size: 80, color: AppTheme.primaryOrange),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.t(context, 'login_title'),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.t(context, 'login_subtitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppTheme.textGrey : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _codigoCtrl,
                    style: TextStyle(color: textColor),
                    textCapitalization: TextCapitalization.characters,
                    decoration: _inputDeco(
                      label: AppLocalizations.t(context, 'login_codigo_instalacion'),
                      icon: Icons.apartment_outlined,
                      isDark: isDark,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? AppLocalizations.t(context, 'required_field') : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _casaDestinoCtrl,
                    style: TextStyle(color: textColor),
                    decoration: _inputDeco(
                      label: AppLocalizations.t(context, 'login_house'),
                      icon: Icons.home_outlined,
                      isDark: isDark,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? AppLocalizations.t(context, 'required_field') : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pinCtrl,
                    obscureText: true,
                    style: TextStyle(color: textColor),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _inputDeco(
                      label: AppLocalizations.t(context, 'login_pin'),
                      icon: Icons.pin_outlined,
                      isDark: isDark,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return AppLocalizations.t(context, 'required_field');
                      if (v.length < 4 || v.length > 6) return AppLocalizations.t(context, 'pin_length_error');
                      return null;
                    },
                  ),
                  if (authVM.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      authVM.error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: authVM.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: authVM.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            AppLocalizations.t(context, 'login_btn'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/registro'),
                    child: Text(
                      AppLocalizations.t(context, 'login_register'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.primaryOrange),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
