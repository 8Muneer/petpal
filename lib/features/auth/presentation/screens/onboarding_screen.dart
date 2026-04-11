import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_button.dart';

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
              Expanded(
                flex: 58,
                child: _MasonryGallery(),
              ),

              // Bottom 42% — content
              Expanded(
                flex: 42,
                child: _BottomContent(
                  onStartPressed: () => context.push('/login'),
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
    for (final t in _timers) t.cancel();
    for (final c in _controllers) c.dispose();
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
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ListView.builder(
                    controller: _controllers[col],
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 120,
                    itemBuilder: (_, index) {
                      final imgIdx = (col + index * 3) % _petImages.length;
                      final h = 110.0 + Random(imgIdx).nextDouble() * 80;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
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
                              child: Icon(
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
            height: 80,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: AppRadius.fullRadius,
                boxShadow: AppShadows.subtle,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pets_rounded,
                      size: 16, color: AppColors.primary),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Headline
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyles.h1.copyWith(fontSize: 24),
              children: [
                const TextSpan(text: 'ברוכים הבאים ל'),
                TextSpan(
                  text: 'PetPal',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'מצא/י מטפל/ת אמין/ה או פרסם/י מודעות אבוד/נמצא בקלות.\nהכל במקום אחד — שירותים, צ׳אט והתראות.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(height: 1.6),
          ),

          const Spacer(),

          // Feature pills row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FeaturePill(
                  icon: Icons.directions_walk_rounded, label: 'טיולים'),
              const SizedBox(width: 8),
              _FeaturePill(icon: Icons.home_work_rounded, label: 'שמירה'),
              const SizedBox(width: 8),
              _FeaturePill(icon: Icons.pets_rounded, label: 'אבודים'),
            ],
          ),

          const SizedBox(height: 20),

          AppButton(
            label: 'בואו נתחיל',
            leadingIcon: Icons.rocket_launch_rounded,
            onTap: onStartPressed,
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: onGuestPressed,
            child: Text(
              'המשך/י כאורח/ת',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
