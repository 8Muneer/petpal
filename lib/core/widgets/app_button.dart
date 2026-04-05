import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petpal/core/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, ghost, danger, outline }

/// Unified button replacing [PrimaryGradientButton].
///
/// Features:
/// - 5 visual variants: primary (gradient), secondary, ghost, danger, outline
/// - Built-in [isLoading] state with spinner — button auto-disables
/// - Haptic feedback on tap
/// - Scale animation on press
/// - Optional leading icon, optional trailing icon
/// - Full-width by default; pass [expand: false] for intrinsic width
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool expand;
  final AppButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? height;

  const AppButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.expand = true,
    this.variant = AppButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.height,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.expand = true,
    this.leadingIcon,
    this.trailingIcon,
    this.height,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.expand = false,
    this.leadingIcon,
    this.trailingIcon,
    this.height,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.expand = true,
    this.leadingIcon,
    this.trailingIcon,
    this.height,
  }) : variant = AppButtonVariant.danger;

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.expand = true,
    this.leadingIcon,
    this.trailingIcon,
    this.height,
  }) : variant = AppButtonVariant.outline;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 160),
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  bool get _isDisabled => widget.onTap == null || widget.isLoading;

  void _onTapDown(TapDownDetails _) {
    if (_isDisabled) return;
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _scaleController.reverse();
    if (_isDisabled) return;
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _onTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    final h = widget.height ?? 52.0;

    Widget content = _buildContent();

    if (widget.expand) {
      content = SizedBox(width: double.infinity, child: content);
    }

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: _buildShell(h, content),
      ),
    );
  }

  Widget _buildShell(double height, Widget content) {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return Container(
          height: height,
          decoration: BoxDecoration(
            gradient: _isDisabled
                ? null
                : AppColors.primaryGradient,
            color: _isDisabled ? AppColors.textMuted : null,
            borderRadius: AppRadius.lgRadius,
            boxShadow: _isDisabled ? null : AppShadows.button,
          ),
          child: content,
        );

      case AppButtonVariant.secondary:
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.primaryFaint,
            borderRadius: AppRadius.lgRadius,
          ),
          child: content,
        );

      case AppButtonVariant.ghost:
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: AppRadius.lgRadius,
          ),
          child: content,
        );

      case AppButtonVariant.danger:
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: _isDisabled ? AppColors.textMuted : AppColors.danger,
            borderRadius: AppRadius.lgRadius,
            boxShadow: _isDisabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: content,
        );

      case AppButtonVariant.outline:
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(
              color: _isDisabled ? AppColors.textMuted : AppColors.primary,
              width: 1.6,
            ),
          ),
          child: content,
        );
    }
  }

  Widget _buildContent() {
    final isPrimary = widget.variant == AppButtonVariant.primary ||
        widget.variant == AppButtonVariant.danger;
    final isGhost = widget.variant == AppButtonVariant.ghost;

    Color fgColor;
    if (isPrimary) {
      fgColor = Colors.white;
    } else if (isGhost || widget.variant == AppButtonVariant.outline) {
      fgColor = _isDisabled ? AppColors.textMuted : AppColors.primary;
    } else {
      fgColor = AppColors.primary;
    }

    if (_isDisabled && !isPrimary) fgColor = AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isLoading) ...[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(fgColor),
              ),
            ),
            const SizedBox(width: 10),
          ] else if (widget.leadingIcon != null) ...[
            Icon(widget.leadingIcon, color: fgColor, size: 18),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              widget.label,
              style: AppTextStyles.buttonText.copyWith(color: fgColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.trailingIcon != null && !widget.isLoading) ...[
            const SizedBox(width: 8),
            Icon(widget.trailingIcon, color: fgColor, size: 18),
          ],
        ],
      ),
    );
  }
}
