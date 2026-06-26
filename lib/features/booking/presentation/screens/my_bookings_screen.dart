import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';
import 'package:petpal/features/booking/presentation/providers/booking_provider.dart';
import 'package:petpal/features/messaging/data/datasources/messaging_datasource.dart';
import 'package:petpal/features/reviews/presentation/providers/review_provider.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text('הזמנות שלי', style: AppTextStyles.headlineSm),
        ),
        body: bookingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('שגיאה: $e')),
          data: (bookings) {
            if (bookings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text('אין הזמנות עדיין',
                        style: AppTextStyles.headlineSm
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text('גלוש לשירותים ושלח בקשת הזמנה',
                        style: AppTextStyles.labelMd
                            .copyWith(color: AppColors.textMuted)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _BookingSummaryCard(booking: bookings[i]),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Summary card — clean, scannable, tap to open detail sheet
// ═══════════════════════════════════════════════════════════════════════════

class _BookingSummaryCard extends StatelessWidget {
  final BookingRequest booking;
  const _BookingSummaryCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final isWalk = booking.serviceType == BookingServiceType.walk;
    final statusInfo = _statusInfo(booking.status);

    return GestureDetector(
      onTap: () => _openDetailSheet(context, booking),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.subtle,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PetAvatar(
              imageUrl: booking.petImageUrl,
              petName: booking.petName,
              size: 60,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pet name + type + status
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          booking.petName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMd
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _Chip(label: booking.petType),
                      const Spacer(),
                      _StatusBadge(label: statusInfo.$1, color: statusInfo.$2),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Sitter line
                  Row(
                    children: [
                      _MiniAvatar(
                        photoUrl: booking.providerPhotoUrl,
                        name: booking.providerName,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          booking.providerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '  •  ${isWalk ? 'טיולי כלבים' : 'שמירה על חיות'}',
                        style: AppTextStyles.labelMd
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Date line
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    text: _dateText(booking),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.chevron_left_rounded,
                  size: 20, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

void _openDetailSheet(BuildContext context, BookingRequest booking) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: false,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: _BookingDetailSheet(booking: booking),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  Detail sheet — full booking story: pet hero, sitter, timeline, actions
// ═══════════════════════════════════════════════════════════════════════════

class _BookingDetailSheet extends ConsumerStatefulWidget {
  final BookingRequest booking;
  const _BookingDetailSheet({required this.booking});

  @override
  ConsumerState<_BookingDetailSheet> createState() =>
      _BookingDetailSheetState();
}

class _BookingDetailSheetState extends ConsumerState<_BookingDetailSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _isOpeningChat = false;
  bool _isUpdating = false;

  BookingRequest get booking => widget.booking;

  Future<void> _confirmCompletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('אישור סיום השירות'),
          content: const Text(
            'מאשר/ת שהשירות בוצע במלואו? לאחר האישור ההזמנה תיסגר ותוכל/י לכתוב ביקורת.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white),
              child: const Text('אשר שהושלם'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    setState(() => _isUpdating = true);
    try {
      await ref
          .read(bookingRepositoryProvider)
          .updateBookingStatus(booking.id, BookingStatus.completed);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאה באישור, נסה שוב')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _disputeCompletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('השירות לא בוצע?'),
          content: const Text(
            'נודיע לשומר שהשירות עדיין לא הושלם, וההזמנה תחזור למצב פעיל. להמשיך?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white),
              child: const Text('השירות לא בוצע'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    setState(() => _isUpdating = true);
    try {
      await ref.read(bookingRepositoryProvider).disputeCompletion(booking.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאה בעדכון, נסה שוב')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('ביטול הזמנה'),
          content: const Text(
            'לבטל את ההזמנה? פעולה זו אינה ניתנת לשחזור והשומר יקבל על כך הודעה.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('חזרה'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white),
              child: const Text('בטל הזמנה'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    setState(() => _isUpdating = true);
    try {
      await ref.read(bookingRepositoryProvider).cancelBooking(booking.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאה בביטול, נסה שוב')),
        );
      }
    }
  }

  Widget _buildCancelButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _isUpdating ? null : _cancelBooking,
        icon: const Icon(Icons.close_rounded, size: 16),
        label: const Text('בטל הזמנה'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.error,
          textStyle: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _fade(Widget child, {required double start, required double end}) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) return child;
    return FadeTransition(
      opacity: CurvedAnimation(
          parent: _ctrl, curve: Interval(start, end, curve: Curves.easeOut)),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _ctrl,
                curve: Interval(start, end, curve: Curves.easeOutCubic))),
        child: child,
      ),
    );
  }

  Future<void> _openChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isOpeningChat = true);
    try {
      final ds = MessagingDatasource(db: FirebaseFirestore.instance);
      final convoId = await ds.getOrCreateConversation(
        myUid: user.uid,
        myName: user.displayName ?? user.email ?? '',
        otherUid: booking.providerUid,
        otherName: booking.providerName,
        myPhotoUrl: user.photoURL ?? '',
        otherPhotoUrl: booking.providerPhotoUrl ?? '',
      );
      if (!mounted) return;
      context.push('/chat/$convoId', extra: {
        'otherName': booking.providerName,
        'otherPhotoUrl': booking.providerPhotoUrl,
        'otherUid': booking.providerUid,
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('שגיאה בפתיחת הצ\'אט')),
      );
    } finally {
      if (mounted) setState(() => _isOpeningChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final bottom = MediaQuery.of(context).viewPadding.bottom;

    // #5: watch the live booking by id so the sheet reflects status changes
    // (e.g. the sitter requesting completion) while it is open. Falls back to
    // the snapshot the sheet was opened with if the list isn't ready.
    final bookings = ref.watch(myBookingsProvider).valueOrNull;
    var booking = widget.booking;
    if (bookings != null) {
      for (final b in bookings) {
        if (b.id == widget.booking.id) {
          booking = b;
          break;
        }
      }
    }

    final isWalk = booking.serviceType == BookingServiceType.walk;
    final statusInfo = _statusInfo(booking.status);

    return Container(
      height: screenH * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // ── Hero photo ──────────────────────────────────────────────
          _Hero(
            booking: booking,
            statusLabel: statusInfo.$1,
            statusColor: statusInfo.$2,
          ),

          // ── Scrollable content ──────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sitter block
                  _fade(_SitterBlock(booking: booking),
                      start: 0.0, end: 0.45),
                  const SizedBox(height: 20),

                  // Timeline
                  _fade(
                    _SectionCard(
                      title: 'מצב ההזמנה',
                      icon: Icons.timeline_rounded,
                      child: _StatusTimeline(status: booking.status),
                    ),
                    start: 0.12,
                    end: 0.55,
                  ),
                  const SizedBox(height: 16),

                  // Details
                  _fade(
                    _SectionCard(
                      title: 'פרטי השירות',
                      icon: Icons.info_outline_rounded,
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'תאריך',
                            value: _dateText(booking),
                          ),
                          _DetailRow(
                            icon: isWalk
                                ? Icons.directions_walk_rounded
                                : Icons.home_rounded,
                            label: 'סוג שירות',
                            value: isWalk
                                ? 'טיול'
                                : booking.sittingType == 'atSitterHome'
                                    ? 'שמירה בבית השומר'
                                    : 'שמירה בבית הבעלים',
                          ),
                          if (booking.specialInstructions?.isNotEmpty == true)
                            _DetailRow(
                              icon: Icons.sticky_note_2_outlined,
                              label: 'הוראות מיוחדות',
                              value: booking.specialInstructions!,
                              isLast:
                                  booking.providerNote?.isNotEmpty != true,
                            ),
                          if (booking.providerNote?.isNotEmpty == true)
                            _DetailRow(
                              icon: Icons.comment_outlined,
                              label: 'הערת השומר',
                              value: booking.providerNote!,
                              isLast: true,
                            ),
                        ],
                      ),
                    ),
                    start: 0.22,
                    end: 0.65,
                  ),

                  // Actions (active for accepted / awaiting / completed)
                  if (booking.status == BookingStatus.accepted ||
                      booking.status == BookingStatus.awaitingConfirmation ||
                      booking.status == BookingStatus.completed) ...[
                    const SizedBox(height: 20),
                    _fade(_buildActions(booking), start: 0.32, end: 0.8),
                  ],

                  // Cancel — owner may cancel until the service is completed
                  if (booking.status == BookingStatus.pending ||
                      booking.status == BookingStatus.accepted ||
                      booking.status ==
                          BookingStatus.awaitingConfirmation) ...[
                    const SizedBox(height: 16),
                    _fade(_buildCancelButton(), start: 0.4, end: 0.9),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BookingRequest booking) {
    final isCompleted = booking.status == BookingStatus.completed;
    final isAwaiting = booking.status == BookingStatus.awaitingConfirmation;
    final existingReview = isCompleted
        ? ref.watch(bookingReviewProvider(booking.id))
        : const AsyncValue.data(null);
    final hasReview = existingReview.valueOrNull != null;

    return Column(
      children: [
        // Chat button — primary gradient
        GestureDetector(
          onTap: _isOpeningChat ? null : _openChat,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: _isOpeningChat
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_rounded,
                            color: Colors.white, size: 19),
                        SizedBox(width: 9),
                        Text(
                          'פתח צ\'אט עם השומר',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (isAwaiting)
          _ConfirmCompletionCard(
            isUpdating: _isUpdating,
            onConfirm: _confirmCompletion,
            onDispute: _disputeCompletion,
          )
        else if (!isCompleted)
          // Accepted: the owner may mark the service complete once its date has
          // arrived (closes the "sitter never requests completion" gap).
          (booking.serviceDateReached
              ? _OwnerCompleteButton(
                  isUpdating: _isUpdating,
                  onTap: _confirmCompletion,
                )
              : _AwaitingCompletionHint(
                  fromLabel: booking.completionAvailableFromLabel,
                ))
        else if (!hasReview)
          _ReviewCtaCard(
            onTap: () => context.push('/reviews/leave', extra: {
              'bookingId': booking.id,
              'providerUid': booking.providerUid,
              'providerName': booking.providerName,
              'providerPhotoUrl': booking.providerPhotoUrl,
            }),
          )
        else
          _SubmittedReviewCard(
            rating: existingReview.value?.rating ?? 5,
            comment: existingReview.value?.comment ?? '',
          ),
      ],
    );
  }
}

// ── Hero header ─────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final BookingRequest booking;
  final String statusLabel;
  final Color statusColor;
  const _Hero({
    required this.booking,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = booking.petImageUrl?.isNotEmpty == true;
    return SizedBox(
      height: 230,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            CachedNetworkImage(
              imageUrl: booking.petImageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => const _HeroPlaceholder(),
              errorWidget: (_, __, ___) => const _HeroPlaceholder(),
            )
          else
            const _HeroPlaceholder(),

          // Scrim
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.22),
                    Colors.black.withValues(alpha: 0.68),
                  ],
                  stops: const [0.0, 0.35, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Handle
          const Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 36,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white54,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45), width: 1),
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),

          // Status badge
          Positioned(
            top: 40,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                statusLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // Name + type
          Positioned(
            bottom: 18,
            right: 20,
            left: 20,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    booking.petName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                            blurRadius: 14,
                            color: Colors.black54,
                            offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    booking.petType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.velvetGradient),
      child: Center(
        child: Icon(Icons.pets_rounded,
            size: 64, color: Colors.white.withValues(alpha: 0.4)),
      ),
    );
  }
}

// ── Sitter block ─────────────────────────────────────────────────────────────

class _SitterBlock extends ConsumerWidget {
  final BookingRequest booking;
  const _SitterBlock({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(providerRatingProvider(booking.providerUid));
    final isWalk = booking.serviceType == BookingServiceType.walk;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primaryFaint,
            backgroundImage: (booking.providerPhotoUrl?.isNotEmpty == true)
                ? CachedNetworkImageProvider(booking.providerPhotoUrl!)
                : null,
            child: (booking.providerPhotoUrl?.isNotEmpty != true)
                ? Text(
                    booking.providerName.isNotEmpty
                        ? booking.providerName.characters.first.toUpperCase()
                        : '?',
                    style: AppTextStyles.headlineSm
                        .copyWith(color: AppColors.primary),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.providerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  isWalk ? 'מטייל/ת כלבים' : 'שומר/ת חיות',
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          // Rating pill
          ratingAsync.maybeWhen(
            data: (r) => r.count > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 15, color: AppColors.warning),
                        const SizedBox(width: 3),
                        Text(
                          r.avg.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.warning,
                          ),
                        ),
                        Text(
                          ' (${r.count})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.bodySm
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Status timeline ──────────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  final BookingStatus status;
  const _StatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(status);
    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          _TimelineNode(
            step: steps[i],
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }

  List<_Step> _buildSteps(BookingStatus status) {
    const sent = _Step(
      icon: Icons.send_rounded,
      title: 'הבקשה נשלחה',
      subtitle: 'הבקשה הועברה לשומר',
      state: _StepState.done,
    );

    switch (status) {
      case BookingStatus.pending:
        return const [
          sent,
          _Step(
            icon: Icons.hourglass_top_rounded,
            title: 'ממתין לאישור',
            subtitle: 'השומר בודק את הבקשה',
            state: _StepState.current,
            color: AppColors.warning,
          ),
        ];
      case BookingStatus.accepted:
        return const [
          sent,
          _Step(
            icon: Icons.check_circle_rounded,
            title: 'הבקשה אושרה',
            subtitle: 'השומר אישר את ההזמנה',
            state: _StepState.done,
            color: AppColors.success,
          ),
          _Step(
            icon: Icons.pets_rounded,
            title: 'השירות פעיל',
            subtitle: 'אפשר לתאם בצ\'אט. הביקורת תיפתח בסיום',
            state: _StepState.current,
            color: AppColors.primary,
          ),
        ];
      case BookingStatus.awaitingConfirmation:
        return const [
          sent,
          _Step(
            icon: Icons.check_circle_rounded,
            title: 'הבקשה אושרה',
            subtitle: 'השומר אישר את ההזמנה',
            state: _StepState.done,
            color: AppColors.success,
          ),
          _Step(
            icon: Icons.fact_check_outlined,
            title: 'ממתין לאישורך',
            subtitle: 'השומר סימן שסיים. אשר/י כדי לדרג',
            state: _StepState.current,
            color: AppColors.sapphire,
          ),
        ];
      case BookingStatus.completed:
        return const [
          sent,
          _Step(
            icon: Icons.check_circle_rounded,
            title: 'הבקשה אושרה',
            subtitle: 'השומר אישר את ההזמנה',
            state: _StepState.done,
            color: AppColors.success,
          ),
          _Step(
            icon: Icons.fact_check_outlined,
            title: 'השומר ביקש אישור',
            subtitle: 'השומר סימן שהשירות הסתיים',
            state: _StepState.done,
            color: AppColors.sapphire,
          ),
          _Step(
            icon: Icons.task_alt_rounded,
            title: 'השירות הושלם',
            subtitle: 'אישרת את סיום השירות. אפשר לכתוב ביקורת',
            state: _StepState.done,
            color: AppColors.primary,
          ),
        ];
      case BookingStatus.declined:
        return const [
          sent,
          _Step(
            icon: Icons.cancel_rounded,
            title: 'הבקשה נדחתה',
            subtitle: 'השומר אינו זמין לבקשה זו',
            state: _StepState.error,
            color: AppColors.error,
          ),
        ];
      case BookingStatus.cancelled:
        return const [
          sent,
          _Step(
            icon: Icons.do_not_disturb_on_rounded,
            title: 'ההזמנה בוטלה',
            subtitle: 'הבקשה בוטלה',
            state: _StepState.muted,
            color: AppColors.textMuted,
          ),
        ];
    }
  }
}

enum _StepState { done, current, error, muted }

class _Step {
  final IconData icon;
  final String title;
  final String subtitle;
  final _StepState state;
  final Color color;
  const _Step({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.state,
    this.color = AppColors.success,
  });
}

class _TimelineNode extends StatelessWidget {
  final _Step step;
  final bool isLast;
  const _TimelineNode({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isMuted = step.state == _StepState.muted;
    final color = step.color;
    final filled =
        step.state == _StepState.done || step.state == _StepState.current;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Node + connector
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: filled
                      ? color.withValues(alpha: 0.14)
                      : (step.state == _StepState.error
                          ? color.withValues(alpha: 0.12)
                          : AppColors.surface),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isMuted
                        ? AppColors.border
                        : color.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(step.icon,
                    size: 16,
                    color: isMuted ? AppColors.textMuted : color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Texts
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isMuted
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.subtitle,
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          if (step.state == _StepState.current)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'עכשיו',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Detail row ───────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryFaint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMd
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Shared sub-widgets
// ═══════════════════════════════════════════════════════════════════════════

class _ReviewCtaCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ReviewCtaCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: AppColors.warning, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'איך היה השירות? כתוב ביקורת',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_left_rounded,
                color: AppColors.warning, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ConfirmCompletionCard extends StatelessWidget {
  final bool isUpdating;
  final VoidCallback onConfirm;
  final VoidCallback onDispute;
  const _ConfirmCompletionCard({
    required this.isUpdating,
    required this.onConfirm,
    required this.onDispute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sapphire.withValues(alpha: 0.06),
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.sapphire.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined,
                  color: AppColors.sapphire, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'השומר סימן שהשירות הושלם',
                  style: AppTextStyles.bodyMd
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'אשר/י כדי לסגור את ההזמנה ולדרג את החוויה. אם השירות לא בוצע, אפשר לסמן שלא הושלם.',
            style: AppTextStyles.labelMd
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          if (isUpdating)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('אשר שהושלם'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                TextButton(
                  onPressed: onDispute,
                  child: Text(
                    'השירות לא בוצע',
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OwnerCompleteButton extends StatelessWidget {
  final bool isUpdating;
  final VoidCallback onTap;
  const _OwnerCompleteButton({required this.isUpdating, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'האם השירות בוצע?',
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'אם השירות הסתיים, סמן/י אותו כהושלם כדי לסגור את ההזמנה ולכתוב ביקורת.',
            style:
                AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: isUpdating
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.task_alt_rounded, size: 18),
                    label: const Text('סמן שהשירות הושלם'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AwaitingCompletionHint extends StatelessWidget {
  final String? fromLabel;
  const _AwaitingCompletionHint({this.fromLabel});

  @override
  Widget build(BuildContext context) {
    final text = fromLabel != null
        ? 'ניתן לסמן שהשירות הושלם החל מ-$fromLabel'
        : 'ניתן לסמן שהשירות הושלם לאחר מועד השירות';
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_rounded,
              color: AppColors.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.labelMd
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmittedReviewCard extends StatelessWidget {
  final int rating;
  final String comment;

  const _SubmittedReviewCard({required this.rating, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'הביקורת שלך:',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star_rounded,
                    color: index < rating
                        ? AppColors.warning
                        : AppColors.textMuted.withValues(alpha: 0.3),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  final String? imageUrl;
  final String petName;
  final double size;
  const _PetAvatar({
    required this.imageUrl,
    required this.petName,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: (imageUrl?.isNotEmpty == true)
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pets_rounded,
                    size: 24, color: AppColors.textMuted),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    petName,
                    style:
                        const TextStyle(fontSize: 9, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  const _MiniAvatar({required this.photoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 9,
      backgroundColor: AppColors.primaryFaint,
      backgroundImage: (photoUrl?.isNotEmpty == true)
          ? CachedNetworkImageProvider(photoUrl!)
          : null,
      child: (photoUrl?.isNotEmpty != true)
          ? Text(
              name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(text,
              style: AppTextStyles.labelMd
                  .copyWith(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppTextStyles.labelSm.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 10)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: AppTextStyles.labelMd
              .copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Shared helpers ───────────────────────────────────────────────────────────

String _dateText(BookingRequest b) {
  if (b.requestedDate != null) return _fmt(b.requestedDate!);
  if (b.startDate != null && b.endDate != null) {
    return '${_fmt(b.startDate!)} – ${_fmt(b.endDate!)}';
  }
  return 'תאריך לא נקבע';
}

String _fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

(String, Color) _statusInfo(BookingStatus status) => switch (status) {
      BookingStatus.pending => ('ממתין', AppColors.warning),
      BookingStatus.accepted => ('אושר', AppColors.success),
      BookingStatus.awaitingConfirmation => ('ממתין לאישורך', AppColors.sapphire),
      BookingStatus.completed => ('הושלם', AppColors.primary),
      BookingStatus.declined => ('נדחה', AppColors.error),
      BookingStatus.cancelled => ('בוטל', AppColors.textMuted),
    };
