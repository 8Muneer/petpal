import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';
import 'package:petpal/features/sitting/presentation/widgets/sitter_calendar_widget.dart';
import 'package:petpal/features/sitting/presentation/widgets/booking_flow_bottom_sheet.dart';
import 'package:petpal/features/profile/presentation/providers/bookings_controller.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petpal/features/sitting/presentation/providers/review_provider.dart';
import 'package:petpal/features/sitting/presentation/widgets/sitter_sentiment_bar.dart';
import 'package:petpal/features/sitting/presentation/widgets/sitter_reputation_gallery.dart';
import 'package:go_router/go_router.dart';

class SitterDetailScreen extends ConsumerStatefulWidget {
  final String sitterId;

  const SitterDetailScreen({super.key, required this.sitterId});

  @override
  ConsumerState<SitterDetailScreen> createState() => _SitterDetailScreenState();
}

class _SitterDetailScreenState extends ConsumerState<SitterDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  // Booking State
  DateTimeRange? _selectedDateRange;
  String? _selectedPetName;
  PetType? _selectedPetType;
  PetGender? _selectedPetGender;
  String? _selectedPetImageUrl;
  bool _isBooking = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sittersAsync = ref.watch(sittingServicesProvider);
    final reviewsAsync = ref.watch(sitterReviewsProvider(widget.sitterId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: sittersAsync.when(
        data: (sitters) {
          final sitter = sitters.where((s) => s.id == widget.sitterId).firstOrNull;

          if (sitter == null) {
            return AppScaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_off_rounded, size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text('המטפל לא נמצא', style: AppTextStyles.headlineMd),
                    const SizedBox(height: 8),
                    Text('ייתכן שהשירות כבר לא זמין.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'חזרה לשוק המטפלים',
                      onTap: () => context.go('/sitting/marketplace'),
                    ),
                  ],
                ),
              ),
            );
          }

          return AppScaffold(
            body: Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                  _buildHero(context, sitter),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginPage),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),
                          _buildAnimatedSection(
                            index: 0,
                            child: _LuxuryStatBento(sitter: sitter),
                          ),
                          const SizedBox(height: 40),
                          _buildAnimatedSection(
                            index: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSectionTitle('אודות השומר'),
                                const SizedBox(height: 16),
                                Text(
                                  sitter.bio ?? 'אין תיאור זמין',
                                  style: AppTextStyles.bodyLg.copyWith(
                                    height: 1.8,
                                    color: AppColors.onSurface.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          _buildAnimatedSection(
                            index: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSectionTitle('דירוגים וחוות דעת'),
                                const SizedBox(height: 16),
                                reviewsAsync.when(
                                  data: (reviews) {
                                    if (reviews.isEmpty) {
                                      return Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        child: Column(
                                          children: [
                                            const Icon(Icons.star_outline_rounded, size: 48, color: AppColors.textMuted),
                                            const SizedBox(height: 12),
                                            Text(
                                              'עדיין אין חוות דעת',
                                              style: AppTextStyles.bodyBold.copyWith(color: AppColors.onSurface),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'היה הראשון לדרג את השירות של ${sitter.providerName}!',
                                              style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SitterSentimentBar(
                                          tagFrequencies: sitter.tagFrequencies,
                                          totalReviews: sitter.reviewCount ?? 0,
                                        ),
                                        const SizedBox(height: 32),
                                        SitterReputationGallery(reviews: reviews),
                                      ],
                                    );
                                  },
                                  loading: () => const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: CircularProgressIndicator(color: AppColors.primary),
                                    ),
                                  ),
                                  error: (err, _) => Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text('לא ניתן לטעון חוות דעת: $err', 
                                      style: AppTextStyles.labelMd.copyWith(color: AppColors.error)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          _buildAnimatedSection(
                            index: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('שירותים וכללים'),
                                const SizedBox(height: 20),
                                _buildServiceTags(sitter),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          _buildAnimatedSection(
                            index: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('יומן זמינות'),
                                const SizedBox(height: 20),
                                SitterCalendarWidget(
                                  availableDates: const [], // TODO: Link to real availability
                                  currentMonth: DateTime.now(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 140), // Space for floating bar
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              _FloatingBookingBar(
                sitter: sitter,
                selectedDateRange: _selectedDateRange,
                selectedPetName: _selectedPetName,
                selectedPetImageUrl: _selectedPetImageUrl,
                isBooking: _isBooking,
                onTap: () => _showBookingFlow(sitter),
              ),
            ],
          ),
        );
      },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('שגיאה בטעינה: $err')),
      ),
    );
  }

  void _showBookingFlow(SittingService sitter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingFlowBottomSheet(
        sitter: sitter,
        onConfirm: (dates, pet) {
          Navigator.pop(context);
          setState(() {
            _selectedDateRange = dates;
            _selectedPetName = pet['name'];
            _selectedPetType = pet['type'];
            _selectedPetGender = pet['gender'];
            _selectedPetImageUrl = pet['imageUrl'];
          });
          _handleBooking(sitter);
        },
      ),
    );
  }

  Future<void> _handleBooking(SittingService sitter) async {
    if (_selectedDateRange == null || _selectedPetName == null) {
      _showBookingFlow(sitter);
      return;
    }

    setState(() => _isBooking = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final profile = ref.read(currentUserProfileProvider).valueOrNull;

      // Calculate Budget (Price per day * days)
      final days = _selectedDateRange!.duration.inDays.clamp(1, 999);
      // Extract price from sitter.priceText (e.g. "₪120/day")
      final priceMatch = RegExp(r'\d+').firstMatch(sitter.priceText);
      final pricePerDay = double.tryParse(priceMatch?.group(0) ?? '0') ?? 0;
      final totalBudget = pricePerDay * days;

      final request = SittingRequest(
        id: '', // Firestore will generate
        ownerUid: user.uid,
        ownerName: profile?.name ?? user.displayName ?? 'בעלים',
        ownerPhotoUrl: profile?.photoUrl ?? user.photoURL,
        petName: _selectedPetName!,
        petType: _selectedPetType ?? PetType.dog,
        petGender: _selectedPetGender,
        petImageUrl: _selectedPetImageUrl,
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end,
        sittingType: sitter.sittingLocation.contains('בית הלקוח') 
            ? SittingType.atOwnerHome 
            : SittingType.atSitterHome,
        area: sitter.area,
        budget: totalBudget.toStringAsFixed(0),
        status: SittingStatus.open,
        isPublicJob: false,
        sitterUid: sitter.providerUid,
        sitterName: sitter.providerName,
        createdAt: DateTime.now(),
      );

      await ref.read(bookingsControllerProvider.notifier).createBooking(request);

      if (!mounted) return;

      // Show Success Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _SuccessDialog(onViewBookings: () {
          Navigator.pop(ctx);
          context.go('/profile/bookings');
        }),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה ביצירת ההזמנה: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 150)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildHero(BuildContext context, SittingService sitter) {
    return SliverAppBar(
      expandedHeight: 450,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      leadingWidth: 80,
      leading: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              sitter.providerPhotoUrl ?? 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=2000',
              fit: BoxFit.cover,
            ),
            // Deep organic gradient
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black54,
                    Colors.black87,
                  ],
                  stops: [0.0, 0.4, 0.8, 1.0],
                ),
              ),
            ),
            // Hero Title Overlay
            Positioned(
              bottom: 40,
              right: AppSpacing.marginPage,
              left: AppSpacing.marginPage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        sitter.providerName,
                        style: AppTextStyles.headlineLg.copyWith(
                          color: Colors.white,
                          fontSize: 36,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (sitter.isVerified) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.verified_rounded, color: Color(0xFF42A5F5), size: 28),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: AppColors.primary.withValues(alpha: 0.9), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        sitter.area,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: AppTextStyles.headlineMd.copyWith(
        fontSize: 22,
        color: AppColors.onSurface,
      ),
    );
  }

  Widget _buildServiceTags(SittingService sitter) {
    final tags = [
      'טיפול בחתולים',
      'טיפול בכלבים',
      sitter.sittingLocation,
      if (sitter.experienceYears > 5) 'מומחה רשום',
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: tags.map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          tag,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      )).toList(),
    );
  }
}

class _LuxuryStatBento extends StatelessWidget {
  final SittingService sitter;
  const _LuxuryStatBento({required this.sitter});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BentoCell(
          icon: Icons.star_rounded,
          value: sitter.rating?.toString() ?? 'חדש',
          label: 'דירוג ממוצע',
          iconColor: const Color(0xFFFFB300),
        ),
        const SizedBox(width: 16),
        _BentoCell(
          icon: Icons.verified_user_rounded,
          value: '${sitter.experienceYears}+',
          label: 'שנות ניסיון',
          iconColor: AppColors.primary,
        ),
        const SizedBox(width: 16),
        _BentoCell(
          icon: Icons.chat_bubble_rounded,
          value: '${sitter.reviewCount ?? 0}',
          label: 'ביקורות',
          iconColor: const Color(0xFF5C6BC0),
        ),
      ],
    );
  }
}

class _BentoCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _BentoCell({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        color: Colors.white.withValues(alpha: 0.6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTextStyles.headlineSm.copyWith(
                fontSize: 18,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSm.copyWith(
                fontSize: 10,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingBookingBar extends StatelessWidget {
  final SittingService sitter;
  final DateTimeRange? selectedDateRange;
  final String? selectedPetName;
  final String? selectedPetImageUrl;
  final bool isBooking;
  final VoidCallback onTap;

  const _FloatingBookingBar({
    required this.sitter,
    required this.selectedDateRange,
    required this.selectedPetName,
    required this.selectedPetImageUrl,
    required this.isBooking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 32,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(32),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.onSurface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedDateRange == null 
                            ? 'בחר תאריכים' 
                            : '${selectedDateRange!.start.day}/${selectedDateRange!.start.month} - ${selectedDateRange!.end.day}/${selectedDateRange!.end.month}',
                        style: AppTextStyles.labelSm.copyWith(color: Colors.white70),
                      ),
                      Text(
                        sitter.priceText,
                        style: AppTextStyles.headlineMd.copyWith(
                          color: AppColors.primary,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  if (selectedPetName != null)
                     Container(
                       width: 40,
                       height: 40,
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         border: Border.all(color: AppColors.primary, width: 2),
                         image: selectedPetImageUrl != null 
                             ? DecorationImage(image: NetworkImage(selectedPetImageUrl!), fit: BoxFit.cover)
                             : null,
                       ),
                       child: selectedPetImageUrl == null 
                           ? const Icon(Icons.pets, color: Colors.white, size: 20) 
                           : null,
                     ),
                  const Spacer(),
                  AppButton(
                    label: isBooking ? 'מעבד...' : 'הזמן עכשיו',
                    expand: false,
                    onTap: isBooking ? null : onTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _SuccessDialog extends StatelessWidget {
  final VoidCallback onViewBookings;

  const _SuccessDialog({required this.onViewBookings});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 64),
            ),
            const SizedBox(height: 24),
            Text('ההזמנה נשלחה!', style: AppTextStyles.headlineMd),
            const SizedBox(height: 12),
            Text(
              'הבקשה שלך הועברה למטפל. תוכל/י לעקוב אחר הסטטוס במסך ההזמנות.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'צפה בהזמנות שלי',
              onTap: onViewBookings,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/sitting/marketplace'),
              child: const Text('חזרה לשוק המטפלים', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
