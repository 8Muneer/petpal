import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petpal/core/theme/app_theme.dart';

/// Unified input field replacing [InputField].
///
/// Features:
/// - Floating label animation (built-in via [labelText])
/// - Inline error message displayed below field
/// - Built-in password visibility toggle when [isPassword] = true
/// - Optional character counter
/// - Optional leading icon
/// - Optional trailing widget (e.g. suffix button)
/// - Keyboard type, text input action support
/// - [onChanged] for real-time validation
class AppInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? errorText;
  final IconData? icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final Widget? suffix;
  final TextDirection textDirection;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? Function(String?)? validator;

  const AppInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onEditingComplete,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.suffix,
    this.textDirection = TextDirection.rtl,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.validator,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final isMultiline = (widget.maxLines ?? 1) > 1;

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword && _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      textDirection: widget.textDirection,
      inputFormatters: widget.inputFormatters,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      validator: widget.validator,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        // Error style
        errorStyle: AppTextStyles.label.copyWith(color: AppColors.danger),
        // Icon
        prefixIcon: widget.icon != null
            ? Icon(widget.icon, size: 20, color: AppColors.textMuted)
            : null,
        // Password toggle or custom suffix
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                tooltip: _obscure ? 'הצג סיסמה' : 'הסתר סיסמה',
              )
            : widget.suffix,
        // Colors
        filled: true,
        fillColor: widget.enabled
            ? AppColors.surfaceCard
            : AppColors.borderFaint,
        // Borders — all defined in theme, but error override here
        border: OutlineInputBorder(
          borderRadius: AppRadius.lgRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgRadius,
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgRadius,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgRadius,
          borderSide: const BorderSide(color: AppColors.borderFaint),
        ),
        // Label style
        labelStyle: AppTextStyles.caption,
        floatingLabelStyle: AppTextStyles.label.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: AppTextStyles.caption,
        // Padding — taller for multiline
        contentPadding: isMultiline
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        // Counter
        counterStyle: AppTextStyles.label,
      ),
    );
  }
}
