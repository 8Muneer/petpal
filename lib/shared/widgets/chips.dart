import 'package:flutter/material.dart';

/// Tiny chip/badge component for labels and status indicators
///
/// Features:
/// - Rounded pill shape
/// - Customizable background and text color
/// - Compact size for inline use
class TinyChip extends StatelessWidget {
  final String text;
  final Color? fill;
  final Color? textColor;

  const TinyChip({
    super.key,
    required this.text,
    this.fill,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: fill ?? const Color(0xFF0F766E).withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: textColor ?? const Color(0xFF0F766E),
        ),
      ),
    );
  }
}

/// Day chip for schedule selection
class DayChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback? onTap;

  const DayChip({
    super.key,
    required this.text,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF0F766E) : const Color(0xFFF1F5F9);
    final fg = selected ? Colors.white : const Color(0xFF334155);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: bg,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: fg,
          ),
        ),
      ),
    );
  }
}
