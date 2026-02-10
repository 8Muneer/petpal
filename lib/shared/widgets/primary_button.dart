import 'package:flutter/material.dart';

/// Primary gradient button with icon and text
///
/// Features:
/// - Gradient background (teal to green)
/// - Icon with semi-transparent container
/// - Customizable text and icon
/// - Elevated shadow effect
class PrimaryGradientButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final double height;
  final List<Color>? gradientColors;

  const PrimaryGradientButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.height = 52,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
      [const Color(0xFF0F766E), const Color(0xFF22C55E)];

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Mini primary button for cards and compact spaces
class MiniPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final List<Color>? gradientColors;

  const MiniPrimaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
      [const Color(0xFF0F766E), const Color(0xFF22C55E)];

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: colors,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Outline button for secondary actions
class OutlineButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;

  const OutlineButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.38)),
          color: accent.withOpacity(0.06),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Solid button with gradient (for actions in cards)
class SolidButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final List<Color>? gradientColors;

  const SolidButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
      [const Color(0xFF0F766E), const Color(0xFF22C55E)];

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: colors,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill-shaped icon button (for top bars)
class PillIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  const PillIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Icon(icon, color: iconColor ?? const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }
}
