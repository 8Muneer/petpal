import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:petpal/features/sitting/presentation/providers/marketplace_provider.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';
import 'package:go_router/go_router.dart';

class SitterMarketplaceScreen extends ConsumerWidget {
  const SitterMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(marketplaceFiltersProvider);
    final sittersAsync = ref.watch(filteredSittingServicesProvider);

    return AppScaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, ref, filters),
          _buildFilterBar(context, ref, filters),
          _buildSittersList(context, sittersAsync),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, MarketplaceFilters filters) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 140,
      backgroundColor: AppColors.surface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: AppColors.surface.withValues(alpha: 0.7),
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'מצא את השומר המושלם לחבר הכי טוב שלך',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, WidgetRef ref, MarketplaceFilters filters) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: TextField(
                  onChanged: (val) => ref.read(marketplaceFiltersProvider.notifier).updateSearch(val),
                  style: AppTextStyles.bodyMd,
                  decoration: InputDecoration(
                    hintText: 'חפש לפי שם, אזור או תיאור...',
                    hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                'ללא חיות נוספות',
                'בבית השומר',
                'בבית הבעלים',
                'ניסיון של 5+ שנים',
                'מאומת',
              ].map((rule) {
                final isSelected = filters.selectedRules.contains(rule);
                return Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: _LuxuryFilterChip(
                    label: rule,
                    isSelected: isSelected,
                    onTap: () => ref.read(marketplaceFiltersProvider.notifier).toggleRule(rule),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSittersList(BuildContext context, AsyncValue sittersAsync) {
    return sittersAsync.when(
      data: (sitters) {
        if (sitters.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              height: 300,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text('לא נמצאו שומרים מתאימים', style: AppTextStyles.bodyLg.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final s = sitters[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 600 + (index * 120)),
                    curve: Curves.easeOutQuart,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 40 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: _BoutiqueSitterCard(sitter: s),
                  ),
                );
              },
              childCount: sitters.length,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
      error: (err, _) => SliverToBoxAdapter(child: Center(child: Text('שגיאה בטעינה: $err'))),
    );
  }
}

class _LuxuryFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LuxuryFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: isSelected ? Colors.white : AppColors.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BoutiqueSitterCard extends StatelessWidget {
  final SittingService sitter;
  const _BoutiqueSitterCard({required this.sitter});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/sitting/detail/${sitter.id}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Column(
            children: [
              // Image Section with badges
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: Image.network(
                      sitter.providerPhotoUrl ?? 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=1000',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Rating Badge
                  Positioned(
                    top: 16,
                    right: 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                (sitter.reviewCount == 0 || sitter.reviewCount == null) ? 'חדש' : '${sitter.rating?.toStringAsFixed(1)} (${sitter.reviewCount})',
                                style: AppTextStyles.bodySm.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Experience Badge
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${sitter.experienceYears} שנות ניסיון',
                            style: AppTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Content Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    sitter.providerName,
                                    style: AppTextStyles.headlineSm.copyWith(fontSize: 20),
                                  ),
                                  if (sitter.isVerified) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified_rounded, color: Color(0xFF42A5F5), size: 18),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sitter.area,
                                style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            sitter.priceText,
                            style: AppTextStyles.headlineSm.copyWith(
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'צפה בפרופיל',
                            variant: AppButtonVariant.secondary,
                            expand: true,
                            onTap: () => context.push('/sitting/sitter/${sitter.id}'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: 'הזמן עכשיו',
                            variant: AppButtonVariant.primary,
                            expand: true,
                            onTap: () {
                              // TODO: Quick booking
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
