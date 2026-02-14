import 'package:flutter/material.dart';

class TinyChip extends StatelessWidget {
  final String text;
  final Color? fill;
  final Color? textColor;
  /// Backwards-compatible alias for [textColor] / auto-derived fill.
  final Color? color;

  const TinyChip({
    super.key,
    required this.text,
    this.fill,
    this.textColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor =
        textColor ?? color ?? const Color(0xFF0F766E);
    final effectiveFill =
        fill ?? effectiveTextColor.withOpacity(0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: effectiveFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: effectiveTextColor,
        ),
      ),
    );
  }
}
