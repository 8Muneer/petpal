import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

/// A premium hero section with parallax image and bottom-floating search bar.
class LuxuryHero extends StatelessWidget {
  final String imageUrl;
  final Widget searchBar;
  final ScrollController scrollController;
  final VoidCallback? onProfileTap;

  const LuxuryHero({
    super.key,
    required this.imageUrl,
    required this.searchBar,
    required this.scrollController,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 420,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Parallax Background Image
            Positioned.fill(
              child: AnimatedBuilder(
                animation: scrollController,
                builder: (context, child) {
                  // Parallax Intensity: 0.3
                  double offset = 0.0;
                  if (scrollController.hasClients) {
                    offset = scrollController.offset * 0.3;
                  }
                  return Stack(
                    children: [
                      Positioned(
                        top: -offset,
                        left: 0,
                        right: 0,
                        height: 530 + 100, // Extra height for parallax travel
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Overlay Gradient
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.2),
                                Colors.transparent,
                                AppColors.surface.withValues(alpha: 0.9),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Branding Overlay (Mobile Style)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: AppSpacing.marginPage,
              right: AppSpacing.marginPage,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onProfileTap,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54, width: 2),
                      ),
                      child: const Icon(Icons.person_outline,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  Text(
                    'PetPal',
                    style: AppTextStyles.headlineLg.copyWith(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Icon(Icons.notifications_none, color: Colors.white),
                ],
              ),
            ),

            // Floating Search Bar (Positioned at bottom)
            Positioned(
              bottom: AppSpacing.marginPage,
              left: AppSpacing.marginPage,
              right: AppSpacing.marginPage,
              child: searchBar,
            ),
          ],
        ),
      ),
    );
  }
}
