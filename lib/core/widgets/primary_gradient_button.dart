import 'package:flutter/material.dart';
import 'package:petpal/core/widgets/app_button.dart';

/// Legacy wrapper — delegates to [AppButton].
class PrimaryGradientButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;

  const PrimaryGradientButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(label: text, leadingIcon: icon, onTap: onTap);
  }
}
