import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/primary_gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const String _logTag = '[OnboardingScreen]';

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('$_logTag $message');
    if (error != null) debugPrint('$_logTag   error: $error');
    if (stackTrace != null) debugPrint('$_logTag   stackTrace: $stackTrace');
  }

  Color get _bgTop => const Color(0xFFECFDF5);
  Color get _bgMid => const Color(0xFFF6F7FB);
  Color get _bgBottom => const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _log('initState');
  }

  @override
  Widget build(BuildContext context) {
    _log('build');

    try {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.surfaceAlabaster,
          body: Stack(
            children: [
              // Background gradient (same family)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [_bgTop, _bgMid, _bgBottom],
                    ),
                  ),
                ),
              ),

              // Blobs
              Positioned(
                top: -120,
                left: -90,
                child: _Blob(
                  size: 260,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF34D399).withOpacity(0.22),
                      const Color(0xFF0EA5E9).withOpacity(0.12),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 120,
                right: -110,
                child: _Blob(
                  size: 290,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF22C55E).withOpacity(0.12),
                      const Color(0xFF0F766E).withOpacity(0.14),
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Top 55% - Masonry Gallery with overlay
                    Expanded(
                      flex: 55,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(AppTheme.superCurveRadius),
                          bottomRight: Radius.circular(AppTheme.superCurveRadius),
                        ),
                        child: Stack(
                          children: [
                            const _MasonryGallery(),

                            // Soft overlay
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.06),
                                      Colors.black.withOpacity(0.02),
                                      Colors.black.withOpacity(0.12),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Small top badge
                            Positioned(
                              top: 14,
                              right: 14,
                              child: _GlassPill(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.pets_rounded,
                                      size: 16,
                                      color: AppColors.secondarySlate.withOpacity(0.75),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'PetPal',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.secondarySlate.withOpacity(0.80),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom 45% - content card
                    Expanded(
                      flex: 45,
                      child: _ContentSection(
                        onStartPressed: () {
                          _log('onStartPressed -> navigate to LoginScreen');
                          try {
                            context.push('/login');
                          } catch (e, st) {
                            _log('navigation to LoginScreen failed', error: e, stackTrace: st);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('navigation failed.')),
                            );
                          }
                        },
                        onGuestPressed: () {
                          _log('onGuestPressed -> navigate to GuestHomeScreen');
                          try {
                            context.go('/guest');
                          } catch (e, st) {
                            _log('navigation to GuestHomeScreen failed', error: e, stackTrace: st);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('navigation failed.')),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, st) {
      _log('build failed', error: e, stackTrace: st);
      return Scaffold(
        backgroundColor: AppColors.surfaceAlabaster,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.alertCoral),
                  const SizedBox(height: 12),
                  const Text(
                    '\u05e9\u05d2\u05d9\u05d0\u05d4 \u05d1\u05de\u05e1\u05da \u05d4\u05e4\u05ea\u05d9\u05d7\u05d4',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondarySlate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.secondarySlate),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}

/// Auto-scrolling masonry gallery with 3 columns
class _MasonryGallery extends StatefulWidget {
  const _MasonryGallery();

  @override
  State<_MasonryGallery> createState() => _MasonryGalleryState();
}

class _MasonryGalleryState extends State<_MasonryGallery> {
  final List<String> _petImages = [
    'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=400&h=500&fit=crop',
    'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400&h=350&fit=crop',
    'https://images.unsplash.com/photo-1425082661705-1834bfd09dca?w=400&h=450&fit=crop',
    'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=400&h=380&fit=crop',
    'https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=400&h=520&fit=crop',
    'https://images.unsplash.com/photo-1452857297128-d9c29adba80b?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=400&h=480&fit=crop',
    'https://images.unsplash.com/photo-1606567595334-d39972c85dfd?w=400&h=360&fit=crop',
    'https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308?w=400&h=440&fit=crop',
    'https://images.unsplash.com/photo-1560807707-8cc77767d783?w=400&h=390&fit=crop',
    'https://images.unsplash.com/photo-1495360010541-f48722b34f7d?w=400&h=510&fit=crop',
    'https://images.unsplash.com/photo-1535591273668-578e31182c4f?w=400&h=370&fit=crop',
  ];

  late List<ScrollController> _controllers;
  late List<Timer> _timers;

  final List<double> _speeds = [0.8, 0.6, 0.7];
  final List<double> _offsets = [0.0, 100.0, 50.0];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => ScrollController(initialScrollOffset: _offsets[i]),
    );
    _timers = [];

    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  void _startAutoScroll() {
    for (int i = 0; i < 3; i++) {
      _timers.add(
        Timer.periodic(const Duration(milliseconds: 50), (timer) {
          if (!_controllers[i].hasClients) return;

          final pos = _controllers[i].position;
          final maxScroll = pos.maxScrollExtent;
          final current = _controllers[i].offset;

          if (current >= maxScroll - 2) {
            _controllers[i].jumpTo(1.0);
          } else {
            _controllers[i].jumpTo(current + _speeds[i]);
          }
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.warmMist,
      child: Row(
        children: List.generate(3, (columnIndex) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ListView.builder(
                controller: _controllers[columnIndex],
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 120,
                itemBuilder: (context, index) {
                  final imageIndex = (columnIndex + index * 3) % _petImages.length;
                  final random = Random(imageIndex);
                  final height = 120.0 + random.nextDouble() * 80;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: AppColors.warmMist,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Image.network(
                          _petImages[imageIndex],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.warmMist,
                              child: Icon(
                                Icons.pets,
                                size: 40,
                                color: AppColors.primarySage.withOpacity(0.5),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppColors.warmMist,
                              child: Center(
                                child: Icon(
                                  Icons.pets,
                                  size: 40,
                                  color: AppColors.primarySage.withOpacity(0.28),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  final VoidCallback onStartPressed;
  final VoidCallback onGuestPressed;

  const _ContentSection({
    required this.onStartPressed,
    required this.onGuestPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
      child: Column(
        children: [
          const SizedBox(height: 10),

          GlassCard(
            useBlur: false,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondarySlate,
                        height: 1.2,
                      ),
                      children: const [
                        TextSpan(text: '\u05d1\u05e8\u05d5\u05db\u05d9\u05dd \u05d4\u05d1\u05d0\u05d9\u05dd \u05dc'),
                        TextSpan(
                          text: 'PetPal',
                          style: TextStyle(color: AppColors.primarySage),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '\u05de\u05e6\u05d0/\u05d9 \u05de\u05d8\u05e4\u05dc/\u05ea \u05d0\u05de\u05d9\u05e0/\u05d4 \u05d0\u05d5 \u05e4\u05e8\u05e1\u05de/\u05d9 \u05de\u05d5\u05d3\u05e2\u05d5\u05ea \u05d0\u05d1\u05d5\u05d3/\u05e0\u05de\u05e6\u05d0 \u05d1\u05e7\u05dc\u05d5\u05ea.\n\u05d4\u05db\u05dc \u05d1\u05de\u05e7\u05d5\u05dd \u05d0\u05d7\u05d3 - \u05e9\u05d9\u05e8\u05d5\u05ea\u05d9\u05dd, \u05e6\u05f3\u05d0\u05d8 \u05d5\u05d4\u05ea\u05e8\u05d0\u05d5\u05ea.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondarySlate.withOpacity(0.68),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 16),

                  PrimaryGradientButton(
                    text: '\u05d1\u05d5\u05d0\u05d5 \u05e0\u05ea\u05d7\u05d9\u05dc',
                    icon: Icons.rocket_launch_rounded,
                    onTap: onStartPressed,
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: onGuestPressed,
                    child: Text(
                      '\u05d4\u05de\u05e9\u05da/\u05d9 \u05db\u05d0\u05d5\u05e8\u05d7/\u05ea',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondarySlate.withOpacity(0.68),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- Small UI helpers ----------

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.gradient});

  final double size;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.62),
        border: Border.all(color: Colors.white.withOpacity(0.52)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
