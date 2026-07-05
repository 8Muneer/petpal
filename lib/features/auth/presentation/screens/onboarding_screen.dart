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
        backgroundColor: const Color(0xFF5A9DBF),
        body: Stack(
          children: [
            // ── Dark gradient overlay (same as login) ─────────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.28, 0.58, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.62),
                      Colors.black.withValues(alpha: 0.28),
                      Colors.black.withValues(alpha: 0.58),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                  ),
                ),
              ),
            ),

            // ── Radial vignette ───────────────────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // ShaderMask fades gallery pixels → transparent at bottom
                  // so background shows through with no hard boundary
                  Expanded(
                    flex: 58,
                    child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.80, 0.97, 1.0],
                        colors: [
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ).createShader(rect),
                      blendMode: BlendMode.dstIn,
                      child: const _MasonryGallery(),
                    ),
                  ),
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

            // ── Logo pill (above everything) ──────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.30),
                  borderRadius: AppRadius.fullRadius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pets_rounded,
                        size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'PetPal',
                      style:
                          AppTextStyles.bodyBold.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
  // Bundled locally so the very first screen never depends on the network.
  static const List<String> _petImages = [
    'assets/images/hero/pet_01.jpg',
    'assets/images/hero/pet_02.jpg',
    'assets/images/hero/pet_03.jpg',
    'assets/images/hero/pet_04.jpg',
    'assets/images/hero/pet_05.jpg',
    'assets/images/hero/pet_06.jpg',
    'assets/images/hero/pet_07.jpg',
    'assets/images/hero/pet_08.jpg',
    'assets/images/hero/pet_09.jpg',
    'assets/images/hero/pet_10.jpg',
    'assets/images/hero/pet_11.jpg',
    'assets/images/hero/pet_12.jpg',
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
    return Stack(
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
                        child: Image.asset(
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
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ),

      ],
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
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyles.h1.copyWith(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              children: [
                const TextSpan(text: 'ברוכים הבאים ל-'),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFD966), Color(0xFFFF9800)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: Text(
                      'PetPal',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.55),
                            blurRadius: 18,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
            style: AppTextStyles.caption.copyWith(
              height: 1.7,
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.82),
              letterSpacing: 0.2,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Feature pills
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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

          const SizedBox(height: 20),

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
                  color: AppColors.primary.withValues(alpha: 0.40),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
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
              Expanded(
                  child: Divider(
                      color: Colors.white.withValues(alpha: 0.35),
                      thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GestureDetector(
                  onTap: onGuestPressed,
                  child: Text(
                    'המשך/י כאורח/ת',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.30),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                  child: Divider(
                      color: Colors.white.withValues(alpha: 0.35),
                      thickness: 1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeaturePill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: AppRadius.fullRadius,
        border: Border.all(color: color.withValues(alpha: 0.40), width: 1),
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
