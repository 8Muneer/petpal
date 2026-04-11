import 'package:flutter/material.dart';
import 'package:petpal/core/widgets/app_card.dart';

/// Legacy wrapper — delegates to [AppCard].
/// Kept for backwards compatibility with existing screen code.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  // ignore: avoid_field_initializers_in_const_classes
  final bool useBlur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.useBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(padding: padding, child: child);
  }
}
