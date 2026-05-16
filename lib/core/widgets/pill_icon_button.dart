import 'package:flutter/material.dart';
import 'package:petpal/core/widgets/glass_card.dart';

class PillIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const PillIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: const EdgeInsets.all(10),
        borderRadius: BorderRadius.circular(16),
        blur: 20,
        opacity: 0.15,
        color: Colors.white,
        child: Icon(icon, size: 22, color: Colors.white),
      ),
    );
  }
}
