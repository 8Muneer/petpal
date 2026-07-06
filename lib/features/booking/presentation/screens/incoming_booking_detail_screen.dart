import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/utils/price_formatter.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';
import 'package:petpal/features/booking/presentation/providers/booking_provider.dart';
import 'package:petpal/features/booking/presentation/widgets/booking_action_buttons.dart';
import 'package:petpal/features/messaging/data/datasources/messaging_datasource.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';

/// Full details of a booking a provider received: who the pet and owner are,
/// every field the owner filled in when booking, and the status-driven
/// accept/decline/complete/cancel actions.
class IncomingBookingDetailScreen extends ConsumerWidget {
  final BookingRequest booking;
  const IncomingBookingDetailScreen({required this.booking, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Prefer the live copy from the stream (status may change after accept/
    // decline) but fall back to the one passed in if it's no longer present
    // (e.g. right after cancellation).
    final live = ref
        .watch(incomingBookingsProvider)
        .asData
        ?.value
        .where((b) => b.id == booking.id)
        .firstOrNull;
    final b = live ?? booking;
    final isWalk = b.serviceType == BookingServiceType.walk;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              _DetailHeader(booking: b),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    _PetHero(booking: b, isWalk: isWalk),
                    const SizedBox(height: 16),
                    _OwnerCard(booking: b),
                    const SizedBox(height: 16),
                    if (b.priceText?.isNotEmpty == true) ...[
                      _PriceBanner(booking: b, isWalk: isWalk),
                      const SizedBox(height: 16),
                    ],
                    const _SectionLabel(text: 'פרטי השירות'),
                    const SizedBox(height: 10),
                    _ServiceDetailsCard(booking: b, isWalk: isWalk),
                    if (_hasCareInfo(b)) ...[
                      const SizedBox(height: 20),
                      const _SectionLabel(text: 'פרטי טיפול'),
                      const SizedBox(height: 10),
                      _CareDetailsCard(booking: b),
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: BookingActionButtons(booking: b),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _hasCareInfo(BookingRequest b) =>
      b.feedingInfo?.isNotEmpty == true ||
      b.medicationInfo?.isNotEmpty == true ||
      b.vetContact?.isNotEmpty == true ||
      b.specialInstructions?.isNotEmpty == true;
}

class _DetailHeader extends StatelessWidget {
  final BookingRequest booking;
  const _DetailHeader({required this.booking});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (booking.status) {
      BookingStatus.pending => ('ממתין', AppColors.warning),
      BookingStatus.accepted => ('אושר', AppColors.success),
      BookingStatus.awaitingConfirmation => ('ממתין לאישור', AppColors.sapphire),
      BookingStatus.completed => ('הושלם', AppColors.primary),
      BookingStatus.declined => ('נדחה', AppColors.error),
      BookingStatus.cancelled => ('בוטל', AppColors.textMuted),
      BookingStatus.expired => ('פג תוקף', AppColors.textMuted),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('פרטי הזמנה', style: AppTextStyles.h2)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(label,
                style: AppTextStyles.labelMd
                    .copyWith(color: color, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: child,
    );
  }
}

/// Hero card: pet photo as a colored backdrop with name/type/service overlaid,
/// mirroring the visual weight the create-booking provider banner has.
class _PetHero extends StatelessWidget {
  final BookingRequest booking;
  final bool isWalk;
  const _PetHero({required this.booking, required this.isWalk});

  IconData get _fallbackIcon =>
      isWalk ? Icons.directions_walk_rounded : Icons.home_work_rounded;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = booking.petImageUrl?.isNotEmpty == true;
    return ClipRRect(
      borderRadius: AppRadius.lgRadius,
      child: Container(
        height: 160,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              CachedNetworkImage(
                imageUrl: booking.petImageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const SizedBox.shrink(),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            // Darken the photo so the overlaid text stays legible.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: hasPhoto ? 0.05 : 0),
                    Colors.black.withValues(alpha: hasPhoto ? 0.55 : 0.15),
                  ],
                ),
              ),
            ),
            if (!hasPhoto)
              Center(
                child: Icon(_fallbackIcon,
                    size: 56, color: Colors.white.withValues(alpha: 0.85)),
              ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isWalk ? Icons.directions_walk_rounded : Icons.home_work_rounded,
                        size: 13, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(isWalk ? 'טיולים' : 'שמירה',
                        style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.primary, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.petName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headlineMd.copyWith(
                                color: Colors.white, fontWeight: FontWeight.w900)),
                        Text(booking.petType,
                            style: AppTextStyles.labelMd
                                .copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerCard extends ConsumerWidget {
  final BookingRequest booking;
  const _OwnerCard({required this.booking});

  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final myProfile = ref.read(currentUserProfileProvider).asData?.value;
    final ds = MessagingDatasource(db: FirebaseFirestore.instance);
    final convoId = await ds.getOrCreateConversation(
      myUid: me.uid,
      myName: me.displayName ?? me.email ?? 'מטפל',
      otherUid: booking.ownerUid,
      otherName: booking.ownerName,
      myPhotoUrl: myProfile?.photoUrl ?? me.photoURL ?? '',
      otherPhotoUrl: booking.ownerPhotoUrl ?? '',
    );
    if (!context.mounted) return;
    context.push('/chat/$convoId', extra: {
      'otherName': booking.ownerName,
      'otherPhotoUrl': booking.ownerPhotoUrl,
      'otherUid': booking.ownerUid,
    });
  }

  Future<void> _call() async {
    final phone = booking.contactPhone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionCard(
      child: Row(
        children: [
          LiveUserAvatar(
            uid: booking.ownerUid,
            fallbackName: booking.ownerName,
            fallbackPhotoUrl: booking.ownerPhotoUrl,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('בעל החיה',
                    style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(booking.ownerName,
                    style: AppTextStyles.bodyLg
                        .copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          _RoundIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            color: AppColors.primary,
            onTap: () => _openChat(context, ref),
          ),
          if (booking.contactPhone?.isNotEmpty == true) ...[
            const SizedBox(width: 8),
            _RoundIconButton(
              icon: Icons.call_rounded,
              color: AppColors.success,
              onTap: _call,
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RoundIconButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 19, color: color),
      ),
    );
  }
}

/// Nights for a sitting booking (null for walks / incomplete dates).
int? _nightsOf(BookingRequest b) {
  if (b.serviceType == BookingServiceType.walk) return null;
  if (b.startDate == null || b.endDate == null) return null;
  final n = b.endDate!.difference(b.startDate!).inDays;
  return n > 0 ? n : null;
}

class _PriceBanner extends StatelessWidget {
  final BookingRequest booking;
  final bool isWalk;
  const _PriceBanner({required this.booking, required this.isWalk});

  @override
  Widget build(BuildContext context) {
    final label = bookingPriceLabel(
      priceText: booking.priceText,
      priceType: booking.priceType,
      hours: isWalk ? booking.hours : null,
      nights: _nightsOf(booking),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded,
              size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Text('הסכום שהוסכם',
              style:
                  AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

String? _timeText(BookingRequest b) {
  if (b.serviceType == BookingServiceType.walk) {
    return b.preferredTime?.isNotEmpty == true ? b.preferredTime : null;
  }
  final drop = b.dropOffTime;
  final pick = b.pickupTime;
  if (drop?.isNotEmpty == true && pick?.isNotEmpty == true) {
    return 'מסירה $drop · איסוף $pick';
  }
  if (drop?.isNotEmpty == true) return 'מסירה $drop';
  if (pick?.isNotEmpty == true) return 'איסוף $pick';
  return null;
}

String? _sittingTypeLabel(String? sittingType) {
  if (sittingType == 'atOwnerHome') return 'בבית הבעלים';
  if (sittingType == 'atSitterHome') return 'בבית השומר';
  return null;
}

class _ServiceDetailsCard extends StatelessWidget {
  final BookingRequest booking;
  final bool isWalk;
  const _ServiceDetailsCard({required this.booking, required this.isWalk});

  @override
  Widget build(BuildContext context) {
    final time = _timeText(booking);
    final nights = _nightsOf(booking);
    final sittingLabel = _sittingTypeLabel(booking.sittingType);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(
              icon: Icons.calendar_today_rounded, text: booking.formattedDateRange),
          if (nights != null) ...[
            const _RowDivider(),
            _DetailRow(
                icon: Icons.nights_stay_rounded, text: '$nights לילות'),
          ],
          if (time != null) ...[
            const _RowDivider(),
            _DetailRow(icon: Icons.access_time_rounded, text: time),
          ],
          if (isWalk && booking.hours != null) ...[
            const _RowDivider(),
            _DetailRow(
                icon: Icons.timelapse_rounded, text: '${booking.hours} שעות'),
          ],
          if (!isWalk && sittingLabel != null) ...[
            const _RowDivider(),
            _DetailRow(icon: Icons.house_rounded, text: sittingLabel),
          ],
          if (booking.location?.isNotEmpty == true) ...[
            const _RowDivider(),
            _DetailRow(
                icon: Icons.location_on_outlined, text: booking.location!),
          ],
        ],
      ),
    );
  }
}

class _CareDetailsCard extends StatelessWidget {
  final BookingRequest booking;
  const _CareDetailsCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    void add(IconData icon, String? text) {
      if (text == null || text.isEmpty) return;
      if (rows.isNotEmpty) rows.add(const _RowDivider());
      rows.add(_DetailRow(icon: icon, text: text));
    }

    add(Icons.restaurant_outlined, booking.feedingInfo);
    add(Icons.medication_outlined, booking.medicationInfo);
    add(Icons.local_hospital_outlined, booking.vetContact);
    add(Icons.info_outline_rounded, booking.specialInstructions);

    return _SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: AppColors.divider),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(text,
                style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
