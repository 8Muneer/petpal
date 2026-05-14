import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/luxury_booking_card.dart';
import 'package:petpal/core/widgets/booking_filter_bar.dart';
import 'package:petpal/features/profile/presentation/providers/bookings_controller.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';
import 'package:petpal/features/sitting/presentation/widgets/review_submission_sheet.dart';
import 'package:petpal/features/sitting/presentation/providers/review_provider.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(unifiedBookingsProvider);
    final bookingsState = ref.watch(bookingsControllerProvider);
    final profile = ref.watch(currentUserProfileProvider).asData?.value;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            children: [
              // --- Custom AppBar ---
              _buildAppBar(profile?.photoUrl),

              // --- Animated Search Bar ---
              _buildAnimatedSearch(),

              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // --- Filter Section ---
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      sliver: SliverToBoxAdapter(
                        child: BookingFilterBar(
                          selectedStatusIndex:
                              bookingsState.selectedStatusIndex,
                          onStatusChanged: (index) => ref
                              .read(bookingsControllerProvider.notifier)
                              .setStatus(index),
                          selectedCategory: bookingsState.selectedCategory,
                          onCategoryChanged: (cat) => ref
                              .read(bookingsControllerProvider.notifier)
                              .setCategory(cat),
                        ),
                      ),
                    ),

                    // --- Bookings List ---
                    bookingsAsync.when(
                      loading: () => const SliverFillRemaining(
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      ),
                      error: (e, _) => SliverFillRemaining(
                        child: Center(child: Text('שגיאה בטעינת הנתונים: $e')),
                      ),
                      data: (bookings) {
                        if (bookings.isEmpty) {
                          return SliverFillRemaining(
                            child: _buildEmptyState(),
                          );
                        }
                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final booking = bookings[index];
                                return TweenAnimationBuilder<double>(
                                  duration: Duration(
                                      milliseconds: 400 + (index * 100)),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: LuxuryBookingCard(
                                    petName: booking.petName,
                                    petPhotoUrl: booking.petPhotoUrl,
                                    title: booking.title,
                                    category: booking.category,
                                    date: booking.date,
                                    time: booking.time,
                                    price: booking.price,
                                    status: booking.status,
                                    isAccepted: booking.isAccepted,
                                    onTap: () {
                                      if (booking.category ==
                                          LuxuryServiceCategory.walks) {
                                        context.push('/walks/detail',
                                            extra: booking.originalRequest);
                                      } else {
                                        context.push('/sitting/detail',
                                            extra: booking.originalRequest);
                                      }
                                    },
                                    onRate: (profile?.uid == booking.reviewerId &&
                                            booking.revieweeId != null)
                                        ? () async {
                                            // Check if it's a repeat booking
                                            final isRepeat = await ref.read(reviewControllerProvider.notifier)
                                                .checkHasReviewed(booking.revieweeId!, booking.reviewerId);
                                            
                                            if (!context.mounted) return;

                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor: Colors.transparent,
                                              builder: (context) => ReviewSubmissionSheet(
                                                bookingId: booking.id,
                                                sitterId: booking.revieweeId!,
                                                sitterName: booking.revieweeName ?? 'המטפל/ת',
                                                isRepeatBooking: isRepeat,
                                              ),
                                            );
                                          }
                                        : null,
                                    onCancel: () {
                                      // Implementation for cancel logic would go here
                                      // For now it shows the dialog inside the card
                                    },
                                  ),
                                );
                              },
                              childCount: bookings.length,
                            ),
                          ),
                        );
                      },
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

  Widget _buildAppBar(String? photoUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.go('/'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: AppColors.onSurface),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ההזמנות שלי', style: AppTextStyles.headlineMd),
                  Text('נהל את לוח הזמנים שלך', style: AppTextStyles.labelMd),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () =>
                    setState(() => _isSearchVisible = !_isSearchVisible),
                icon: Icon(_isSearchVisible
                    ? Icons.close_rounded
                    : Icons.search_rounded),
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: ClipOval(
                  child: photoUrl != null
                      ? Image.network(photoUrl, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.surface,
                          child: const Icon(Icons.person, size: 20)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSearch() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isSearchVisible ? 60 : 0,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) =>
                ref.read(bookingsControllerProvider.notifier).setSearch(val),
            decoration: const InputDecoration(
              hintText: 'חפש לפי שם חיה או סוג שירות...',
              border: InputBorder.none,
              icon: Icon(Icons.search_rounded,
                  size: 20, color: AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.calendar_today_rounded,
              size: 48, color: AppColors.border),
        ),
        const SizedBox(height: 24),
        Text('אין הזמנות תואמות', style: AppTextStyles.headlineSm),
        const SizedBox(height: 8),
        Text('נסה לשנות את הפילטרים או לחפש משהו אחר',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            ref.read(bookingsControllerProvider.notifier).setCategory('All');
            ref.read(bookingsControllerProvider.notifier).setStatus(0);
            ref.read(bookingsControllerProvider.notifier).setSearch('');
            _searchController.clear();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.onSurface,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('נקה הכל'),
        ),
      ],
    );
  }
}
