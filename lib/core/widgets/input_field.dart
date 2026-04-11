import 'package:flutter/material.dart';
import 'package:petpal/core/widgets/app_input.dart';

/// Legacy wrapper — delegates to [AppInput].
class InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const InputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return AppInput(
      controller: controller,
      label: label,
      hint: hint,
      icon: icon,
      isPassword: obscureText,
      keyboardType: keyboardType,
      textDirection: TextDirection.ltr,
    );
  }
}
