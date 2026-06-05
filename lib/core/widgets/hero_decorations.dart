import 'package:flutter/material.dart';

/// Shared hero decorations used across the luxury screens
/// (profile, provider profile, leave-review).
///
/// Previously these were duplicated as private classes in
/// `luxury_hero.dart` and `profile_screen.dart`. Extracted here so the
/// Nautical Depths hero treatment stays consistent in one place.

/// Faint dot-grid shimmer painted over a dark gradient hero.
class DotGridPainter extends CustomPainter {
  const DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    const spacing = 18.0;
    const r = 1.2;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DotGridPainter old) => false;
}

/// Soft double-wave that clips the bottom edge of a hero into the
/// surface below it.
class HeroWaveClipper extends CustomClipper<Path> {
  const HeroWaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.65);
    path.quadraticBezierTo(
      size.width * 0.25,
      0,
      size.width * 0.5,
      size.height * 0.38,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.72,
      size.width,
      size.height * 0.18,
    );
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(HeroWaveClipper old) => false;
}
