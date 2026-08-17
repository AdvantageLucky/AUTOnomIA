import 'package:flutter/material.dart';

/// Input estándar con label — usa el InputDecorationTheme ya definido en
/// AppTheme, solo añade el patrón controller+label+validator repetido en
/// cada formulario de la app.
class KigoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final bool obscureText;
  final int? maxLength;
  final String? Function(String?)? validator;

  const KigoTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLength,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(labelText: label, counterText: ''),
    );
  }
}
