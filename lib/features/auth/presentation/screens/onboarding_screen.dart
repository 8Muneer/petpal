import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surfaceCard,
        body: SafeArea(
          child: Column(
            children: [
              // Top 58% — auto-scrolling masonry gallery
              const Expanded(
                flex: 58,
                child: _MasonryGallery(),
              ),

              // Bottom 42% — content
              Expanded(
                flex: 42,
                child: _BottomContent(
                  onStartPressed: () {
                    debugPrint('🚀 Let\'s start pressed');
                    context.push('/login');
                  },
                  onGuestPressed: () => context.go('/guest'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Auto-scrolling masonry gallery ──────────────────────────────────────────

class _MasonryGallery extends StatefulWidget {
  const _MasonryGallery();

  @override
  State<_MasonryGallery> createState() => _MasonryGalleryState();
}

class _MasonryGalleryState extends State<_MasonryGallery> {
  static const List<String> _petImages = [
    'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=400&h=500&fit=crop',
    'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=400&h=350&fit=crop',
    'https://images.unsplash.com/photo-1537151608828-ea2b11777ee8?w=400&h=450&fit=crop',
    'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=400&h=380&fit=crop',
    'https://images.unsplash.com/photo-1598133894008-61f7fdb8cc3a?w=400&h=520&fit=crop',
    'https://images.unsplash.com/photo-1530281700549-e82e7bf110d6?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=400&h=480&fit=crop',
    'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=400&h=360&fit=crop',
    'https://images.unsplash.com/photo-1552053831-71594a27632d?w=400&h=440&fit=crop',
    'https://images.unsplash.com/photo-1518717758536-85ae29035b6d?w=400&h=390&fit=crop',
    'https://images.unsplash.com/photo-1561037404-61cd46aa615b?w=400&h=510&fit=crop',
    'https://images.unsplash.com/photo-1507146426996-ef05306b995a?w=400&h=370&fit=crop',
  ];

  late List<ScrollController> _controllers;
  late List<Timer> _timers;
  static const List<double> _speeds = [0.8, 0.6, 0.7];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => ScrollController(initialScrollOffset: i * 60.0),
    );
    _timers = [];
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  void _startAutoScroll() {
    for (int i = 0; i < 3; i++) {
      _timers.add(
        Timer.periodic(const Duration(milliseconds: 50), (timer) {
          if (!mounted || !_controllers[i].hasClients) return;
          final pos = _controllers[i].position;
          final current = _controllers[i].offset;
          if (current >= pos.maxScrollExtent - 2) {
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
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: Stack(
        children: [
          Row(
            children: List.generate(3, (col) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ListView.builder(
                    controller: _controllers[col],
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 120,
                    itemBuilder: (_, index) {
                      final imgIdx = (col + index * 3) % _petImages.length;
                      final h = 110.0 + Random(imgIdx).nextDouble() * 80;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            _petImages[imgIdx],
                            height: h,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: h,
                              color: AppColors.borderFaint,
                              child: const Icon(
                                Icons.pets,
                                color: AppColors.textMuted,
                                size: 32,
                              ),
                            ),
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                height: h,
                                color: AppColors.borderFaint,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
          ),

          // Bottom fade to white
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 110,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),

          // Top logo pill
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: AppRadius.fullRadius,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pets_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'PetPal',
                    style: AppTextStyles.bodyBold
                        .copyWith(color: AppColors.textPrimary),
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

// ─── Bottom content section ───────────────────────────────────────────────────

class _BottomContent extends StatelessWidget {
  final VoidCallback onStartPressed;
  final VoidCallback onGuestPressed;

  const _BottomContent({
    required this.onStartPressed,
    required this.onGuestPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.surfaceCard,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Paw watermark + headline
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.pets_rounded,
                  size: 100,
                  color: AppColors.primary.withValues(alpha: 0.04),
                ),
                Column(
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTextStyles.h1.copyWith(
                            fontSize: 26, color: AppColors.textPrimary),
                        children: [
                          const TextSpan(text: 'ברוכים הבאים ל-'),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.regalNavy,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds),
                              child: Text(
                                'PetPal',
                                style: AppTextStyles.h1.copyWith(
                                  fontSize: 26,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'מצא/י מטפל/ת אמין/ה או פרסם/י מודעות אבוד/נמצא בקלות.\nהכל במקום אחד — שירותים, צ׳אט והתראות.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(height: 1.7),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),

            // Feature pills — each with its own accent colour
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _FeaturePill(
                  icon: Icons.directions_walk_rounded,
                  label: 'טיולים',
                  color: AppColors.sapphire,
                ),
                SizedBox(width: 10),
                _FeaturePill(
                  icon: Icons.home_work_rounded,
                  label: 'שמירה',
                  color: AppColors.success,
                ),
                SizedBox(width: 10),
                _FeaturePill(
                  icon: Icons.pets_rounded,
                  label: 'אבודים',
                  color: AppColors.warning,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Gradient CTA button
            Container(
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.regalNavy],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onStartPressed,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'בואו נתחיל',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Divider-style guest link
            Row(
              children: [
                const Expanded(
                    child: Divider(color: AppColors.divider, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GestureDetector(
                    onTap: onGuestPressed,
                    child: Text(
                      'המשך/י כאורח/ת',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Expanded(
                    child: Divider(color: AppColors.divider, thickness: 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeaturePill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.fullRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
