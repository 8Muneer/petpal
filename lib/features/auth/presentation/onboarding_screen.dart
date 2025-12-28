import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlabaster,
      body: SafeArea(
        child: Column(
          children: [
            // Top 55% - Masonry Gallery
            Expanded(
              flex: 55,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.superCurveRadius),
                  bottomRight: Radius.circular(AppTheme.superCurveRadius),
                ),
                child: const _MasonryGallery(),
              ),
            ),
            // Bottom 45% - Content Section
            Expanded(
              flex: 45,
              child: _ContentSection(
                onStartPressed: () {
                  // TODO: Navigate to Login/Register
                },
                onGuestPressed: () {
                  // TODO: Navigate as Guest
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Auto-scrolling masonry gallery with 3 columns
class _MasonryGallery extends StatefulWidget {
  const _MasonryGallery();

  @override
  State<_MasonryGallery> createState() => _MasonryGalleryState();
}

class _MasonryGalleryState extends State<_MasonryGallery> {
  // Pet placeholder images (using picsum with pet-like seeds)
  final List<String> _petImages = [
    'https://picsum.photos/seed/dog1/400/500',
    'https://picsum.photos/seed/cat1/400/350',
    'https://picsum.photos/seed/pet3/400/450',
    'https://picsum.photos/seed/dog2/400/380',
    'https://picsum.photos/seed/cat2/400/520',
    'https://picsum.photos/seed/pet6/400/400',
    'https://picsum.photos/seed/dog3/400/480',
    'https://picsum.photos/seed/cat3/400/360',
    'https://picsum.photos/seed/pet9/400/440',
    'https://picsum.photos/seed/dog4/400/390',
    'https://picsum.photos/seed/cat4/400/510',
    'https://picsum.photos/seed/pet12/400/370',
  ];

  // Scroll controllers for each column
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
        3, (i) => ScrollController(initialScrollOffset: _offsets[i]));
    _timers = [];

    // Start auto-scrolling after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    for (int i = 0; i < 3; i++) {
      _timers.add(Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (_controllers[i].hasClients) {
          final maxScroll = _controllers[i].position.maxScrollExtent;
          final currentScroll = _controllers[i].offset;

          if (currentScroll >= maxScroll) {
            _controllers[i].jumpTo(0);
          } else {
            _controllers[i].jumpTo(currentScroll + _speeds[i]);
          }
        }
      }));
    }
  }

  @override
  void dispose() {
    for (var timer in _timers) {
      timer.cancel();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
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
                final height =
                    120.0 + random.nextDouble() * 80; // Random height 120-200

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
                                color: AppColors.primarySage.withOpacity(0.3),
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
    );
  }
}

/// Bottom content section with headline, subtext, and CTAs
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
          // Headline with highlighted city
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.secondarySlate,
                height: 1.2,
              ),
              children: [
                const TextSpan(text: 'Find the Perfect Care\nfor Your '),
                TextSpan(
                  text: 'Furry Friend',
                  style: TextStyle(
                    color: AppColors.primarySage,
                  ),
                ),
                const TextSpan(text: '!'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Subtext description
          Text(
            'Verified sitters, real-time updates, and\npay only 10% now—rest upon arrival.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondarySlate.withOpacity(0.7),
              height: 1.5,
            ),
          ),
          const Spacer(flex: 2),
          // Primary CTA Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onStartPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySage,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.superCurveRadius),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Start Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary Link
          TextButton(
            onPressed: onGuestPressed,
            child: Text(
              'Browse as Guest',
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
