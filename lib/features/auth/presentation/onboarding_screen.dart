import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/auth/presentation/login_screen.dart';
import 'package:petpal/features/auth/presentation/guest_home_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _log('initState');
  }

  @override
  Widget build(BuildContext context) {
    _log('build');
    try {
      return Scaffold(
        backgroundColor: AppColors.surfaceAlabaster,
        body: SafeArea(
          child: Column(
            children: [
              // ✅ Top 55% - Masonry Gallery (same as old)
              const Expanded(
                flex: 55,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AppTheme.superCurveRadius),
                    bottomRight: Radius.circular(AppTheme.superCurveRadius),
                  ),
                  child: _MasonryGallery(),
                ),
              ),

              // ✅ Bottom 45% - Your new content section
              Expanded(
                flex: 45,
                child: _ContentSection(
                  onStartPressed: () {
                    _log('onStartPressed -> navigate to LoginScreen');
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    } catch (e, st) {
                      _log('navigation to LoginScreen failed',
                          error: e, stackTrace: st);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('הניווט נכשל. נסה/י שוב.')),
                      );
                    }
                  },
                  onGuestPressed: () {
                    _log('onGuestPressed -> navigate to GuestHomeScreen');
                    try {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GuestHomeScreen()),
                      );
                    } catch (e, st) {
                      _log('navigation to GuestHomeScreen failed',
                          error: e, stackTrace: st);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('הניווט נכשל. נסה/י שוב.')),
                      );
                    }
                  },
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
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.alertCoral),
                  const SizedBox(height: 12),
                  const Text(
                    'שגיאה במסך הפתיחה',
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

/// Auto-scrolling masonry gallery with 3 columns (same as old)
class _MasonryGallery extends StatefulWidget {
  const _MasonryGallery();

  @override
  State<_MasonryGallery> createState() => _MasonryGalleryState();
}

class _MasonryGalleryState extends State<_MasonryGallery> {
  // Real pet images from Unsplash
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

  // Different speeds for each column (pixels per tick)
  final List<double> _speeds = [0.8, 0.6, 0.7];

  // Staggered offsets for organic look
  final List<double> _offsets = [0.0, 100.0, 50.0];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => ScrollController(initialScrollOffset: _offsets[i]),
    );
    _timers = [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    for (int i = 0; i < 3; i++) {
      _timers.add(
        Timer.periodic(const Duration(milliseconds: 50), (timer) {
          if (!_controllers[i].hasClients) return;

          final maxScroll = _controllers[i].position.maxScrollExtent;
          final currentScroll = _controllers[i].offset;

          if (currentScroll >= maxScroll) {
            _controllers[i].jumpTo(0);
          } else {
            _controllers[i].jumpTo(currentScroll + _speeds[i]);
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
      color: AppColors.warmMist, // background behind tiles
      child: Row(
        children: List.generate(3, (columnIndex) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ListView.builder(
                controller: _controllers[columnIndex],
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 100, // Infinite-like scroll
                itemBuilder: (context, index) {
                  final imageIndex =
                      (columnIndex + index * 3) % _petImages.length;

                  final random = Random(imageIndex);
                  final height = 120.0 + random.nextDouble() * 80;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: AppColors.warmMist,
                          borderRadius: BorderRadius.circular(16),
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
                                color:
                                    AppColors.primarySage.withOpacity(0.5),
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
                                  color:
                                      AppColors.primarySage.withOpacity(0.3),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.secondarySlate,
                height: 1.3,
              ),
              children: [
                TextSpan(text: 'ברוך הבא ל־'),
                TextSpan(
                  text: 'PetPal',
                  style: TextStyle(color: AppColors.primarySage),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'מצא מטפל אמין או פרסם מודעות אבוד/נמצא בקלות ובמהירות.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondarySlate.withOpacity(0.65),
              height: 1.6,
            ),
          ),
          const Spacer(flex: 1),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onStartPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySage,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'התחל',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onGuestPressed,
            child: Text(
              'המשך כאורח',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondarySlate.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
