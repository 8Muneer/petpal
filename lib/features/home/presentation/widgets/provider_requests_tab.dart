import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/utils/price_formatter.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
import 'package:petpal/core/widgets/app_header_bar.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/section_header.dart';

import 'package:petpal/features/walks/domain/entities/walk_request.dart';
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart'
    show SittingRequest, PetType, PetGender;
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';
import 'package:petpal/features/booking/presentation/providers/booking_provider.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';
import 'package:petpal/features/booking/presentation/widgets/booking_status_toggle.dart';
import 'package:petpal/features/applications/presentation/widgets/service_application_sheet.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';
import 'package:petpal/features/messaging/data/datasources/messaging_datasource.dart';

class ProviderRequestsTab extends ConsumerStatefulWidget {
  const ProviderRequestsTab({super.key});

  @override
  ConsumerState<ProviderRequestsTab> createState() =>
      _ProviderAllRequestsTabState();
}

class _ProviderAllRequestsTabState extends ConsumerState<ProviderRequestsTab> {
  int _selected = 0; // 0 = walk, 1 = sitting

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeaderBar(title: 'הבקשות'),
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: GlassCard(
                  useBlur: true,
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ProviderToggleChip(
                          label: 'טיולים',
                          icon: Icons.directions_walk_rounded,
                          selected: _selected == 0,
                          onTap: () => setState(() => _selected = 0),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ProviderToggleChip(
                          label: 'שמירה',
                          icon: Icons.home_work_rounded,
                          selected: _selected == 1,
                          onTap: () => setState(() => _selected = 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: switch (_selected) {
                    1 => const _ProviderSittingRequestsView(
                        key: ValueKey('req_sitting')),
                    _ => const _ProviderRequestsView(key: ValueKey('req_walk')),
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Incoming bookings — moved out of the הבקשות tab and into the profile menu,
// since it's about confirmed/pending orders rather than open marketplace
// requests to bid on.

class ProviderBookingsScreen extends StatelessWidget {
  const ProviderBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('הזמנות', style: AppTextStyles.h2),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Expanded(child: _IncomingBookingsView()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderRequestsView extends ConsumerWidget {
  const _ProviderRequestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(openWalkRequestsProvider);
    return requestsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('שגיאה בטעינת הבקשות: $e')),
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_walk_rounded,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text('אין בקשות טיול פתוחות כרגע',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                const Text('כשבעל חיה יפרסם בקשה — תופיע כאן',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted)),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SectionHeader(
                title: 'בקשות טיול פתוחות',
                subtitle: '${requests.length} בקשות זמינות כרגע',
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.44,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: requests.length,
                itemBuilder: (ctx, i) => _ProviderWalkRequestCard(
                  request: requests[i],
                  colorIndex: i,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProviderWalkRequestCard extends StatelessWidget {
  final WalkRequest request;
  final int colorIndex;
  const _ProviderWalkRequestCard(
      {required this.request, required this.colorIndex});

  static const _bgColors = [
    AppColors.sapphire,
    AppColors.blueSlate,
    AppColors.regalNavy,
    AppColors.smartBlue,
    AppColors.prussianBlue2,
    AppColors.prussianBlue,
    AppColors.twilightIndigo,
    AppColors.blueSlate,
  ];

  String get _petTypeLabel {
    switch (request.petType) {
      case PetType.dog:
        return 'כלב';
      case PetType.cat:
        return 'חתול';
      case PetType.other:
        return 'אחר';
    }
  }

  String get _genderLabel {
    if (request.petGender == PetGender.male) return 'זכר';
    if (request.petGender == PetGender.female) return 'נקבה';
    return '';
  }

  IconData get _fallbackIcon {
    switch (request.petType) {
      case PetType.dog:
        return Icons.directions_walk_rounded;
      case PetType.cat:
        return Icons.pets_rounded;
      case PetType.other:
        return Icons.cruelty_free_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bgColors[colorIndex % _bgColors.length];
    final hasPetPhoto =
        request.petImageUrl != null && request.petImageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => context.push('/walks/detail', extra: request),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Pet photo area ───────────────────────────────────────────
            Expanded(
              flex: 56,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: bg),
                    if (hasPetPhoto)
                      CachedNetworkImage(
                        imageUrl: request.petImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Center(
                          child: Icon(_fallbackIcon,
                              size: 52,
                              color: Colors.white.withValues(alpha: 0.6)),
                        ),
                        errorWidget: (_, __, ___) => Center(
                          child: Icon(_fallbackIcon,
                              size: 52,
                              color: Colors.white.withValues(alpha: 0.6)),
                        ),
                      )
                    else
                      Center(
                        child: Icon(_fallbackIcon,
                            size: 60,
                            color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    // Heart icon
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_border_rounded,
                            size: 16, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Info area ────────────────────────────────────────────────
            Expanded(
              flex: 44,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.petName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _petTypeLabel,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: [
                        if (_genderLabel.isNotEmpty)
                          _IconChip(
                            icon: Icons.transgender_rounded,
                            label: _genderLabel,
                            color: request.petGender == PetGender.female
                                ? AppColors.error
                                : AppColors.smartBlue,
                          ),
                        _IconChip(
                          icon: Icons.location_on_rounded,
                          label: request.area,
                          color: AppColors.error,
                        ),
                        _IconChip(
                          icon: Icons.timer_rounded,
                          label: request.duration,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        LiveUserAvatar(
                          uid: request.ownerUid,
                          fallbackName: request.ownerName,
                          fallbackPhotoUrl: request.ownerPhotoUrl,
                          size: 20,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            request.ownerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: GestureDetector(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => ServiceApplicationSheet(
                            requestType: 'walk',
                            requestId: request.id,
                            ownerUid: request.ownerUid,
                            ownerName: request.ownerName,
                            petName: request.petName,
                            summaryChips: [
                              if (request.area.isNotEmpty) request.area,
                              if (request.preferredTime.isNotEmpty)
                                request.preferredTime,
                              if (request.budget != null &&
                                  request.budget!.isNotEmpty)
                                'תקציב: ${withShekel(request.budget!)}',
                            ],
                          ),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.accent],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'הגש מועמדות',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11),
                            ),
                          ),
                        ),
                      ),
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

class _OfferSummaryItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _OfferSummaryItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
      ],
    );
  }
}

class _OfferInputField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final int minLines;
  final String? prefix;
  final TextInputType? keyboardType;

  const _OfferInputField({
    required this.hint,
    required this.controller,
    this.maxLines = 4,
    this.minLines = 1,
    this.prefix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      textDirection: TextDirection.rtl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        prefixText: prefix,
        prefixStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 14),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _ProviderSittingRequestsView extends ConsumerWidget {
  const _ProviderSittingRequestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(openSittingRequestsProvider);
    return requestsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_work_rounded,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text('אין בקשות שמירה פתוחות כרגע',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                const Text('כשבעל חיה יפרסם בקשה — תופיע כאן',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted)),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SectionHeader(
                title: 'בקשות שמירה פתוחות',
                subtitle: '${requests.length} בקשות זמינות כרגע',
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.44,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: requests.length,
                itemBuilder: (ctx, i) => _ProviderSittingRequestCard(
                  request: requests[i],
                  colorIndex: i,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProviderSittingRequestCard extends StatelessWidget {
  final SittingRequest request;
  final int colorIndex;
  const _ProviderSittingRequestCard(
      {required this.request, required this.colorIndex});

  static const _bgColors = [
    AppColors.blueSlate,
    AppColors.smartBlue,
    AppColors.sapphire,
    AppColors.regalNavy,
    AppColors.twilightIndigo,
    AppColors.prussianBlue,
    AppColors.prussianBlue2,
    AppColors.blueSlate,
  ];

  String get _petTypeLabel {
    switch (request.petType) {
      case PetType.dog:
        return 'כלב';
      case PetType.cat:
        return 'חתול';
      case PetType.other:
        return 'אחר';
    }
  }

  String get _genderLabel {
    if (request.petGender == PetGender.male) return 'זכר';
    if (request.petGender == PetGender.female) return 'נקבה';
    return '';
  }

  IconData get _fallbackIcon {
    switch (request.petType) {
      case PetType.dog:
        return Icons.directions_walk_rounded;
      case PetType.cat:
        return Icons.pets_rounded;
      case PetType.other:
        return Icons.cruelty_free_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bgColors[colorIndex % _bgColors.length];
    final hasPetPhoto =
        request.petImageUrl != null && request.petImageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => context.push('/sitting/detail', extra: request),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Pet photo area ───────────────────────────────────────────
            Expanded(
              flex: 56,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: bg),
                    if (hasPetPhoto)
                      CachedNetworkImage(
                        imageUrl: request.petImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Center(
                          child: Icon(_fallbackIcon,
                              size: 52,
                              color: Colors.white.withValues(alpha: 0.6)),
                        ),
                        errorWidget: (_, __, ___) => Center(
                          child: Icon(_fallbackIcon,
                              size: 52,
                              color: Colors.white.withValues(alpha: 0.6)),
                        ),
                      )
                    else
                      Center(
                        child: Icon(_fallbackIcon,
                            size: 60,
                            color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    // Heart icon
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_border_rounded,
                            size: 16, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Info area ────────────────────────────────────────────
            Expanded(
              flex: 44,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.petName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _petTypeLabel,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: [
                        if (_genderLabel.isNotEmpty)
                          _IconChip(
                            icon: Icons.transgender_rounded,
                            label: _genderLabel,
                            color: request.petGender == PetGender.female
                                ? AppColors.error
                                : AppColors.smartBlue,
                          ),
                        _IconChip(
                          icon: Icons.location_on_rounded,
                          label: request.area,
                          color: AppColors.error,
                        ),
                        if (request.numberOfNights > 0)
                          _IconChip(
                            icon: Icons.nights_stay_rounded,
                            label: '${request.numberOfNights} לילות',
                            color: AppColors.regalNavy,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        LiveUserAvatar(
                          uid: request.ownerUid,
                          fallbackName: request.ownerName,
                          fallbackPhotoUrl: request.ownerPhotoUrl,
                          size: 20,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            request.ownerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: GestureDetector(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              _SittingProviderOfferSheet(request: request),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.accent],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'הגש מועמדות',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11),
                            ),
                          ),
                        ),
                      ),
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

class _SittingProviderOfferSheet extends ConsumerStatefulWidget {
  final SittingRequest request;
  const _SittingProviderOfferSheet({required this.request});

  @override
  ConsumerState<_SittingProviderOfferSheet> createState() =>
      _SittingProviderOfferSheetState();
}

class _SittingProviderOfferSheetState
    extends ConsumerState<_SittingProviderOfferSheet> {
  final _messageController = TextEditingController();
  final _priceController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      _showSnack('יש להוסיף הודעה');
      return;
    }
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    setState(() => _sending = true);

    try {
      final req = widget.request;
      final myProfile = ref.read(currentUserProfileProvider).asData?.value;
      final myPhotoUrl = myProfile?.photoUrl ?? me.photoURL ?? '';
      final ownerPhotoUrl = req.ownerPhotoUrl ?? '';

      final ds = MessagingDatasource(db: FirebaseFirestore.instance);
      final convoId = await ds.getOrCreateConversation(
        myUid: me.uid,
        myName: me.displayName ?? me.email ?? 'מטפל',
        otherUid: req.ownerUid,
        otherName: req.ownerName,
        myPhotoUrl: myPhotoUrl,
        otherPhotoUrl: ownerPhotoUrl,
      );

      final startStr = req.startDate != null
          ? '${req.startDate!.day.toString().padLeft(2, '0')}/${req.startDate!.month.toString().padLeft(2, '0')}'
          : '';
      final endStr = req.endDate != null
          ? '${req.endDate!.day.toString().padLeft(2, '0')}/${req.endDate!.month.toString().padLeft(2, '0')}'
          : '';

      await ds.sendContextMessage(
        conversationId: convoId,
        senderId: me.uid,
        metadata: {
          'requestType': 'sitting',
          'requestId': req.id,
          'petName': req.petName,
          'petImageUrl': req.petImageUrl ?? '',
          'ownerName': req.ownerName,
          'ownerPhotoUrl': ownerPhotoUrl,
          'date': startStr.isNotEmpty && endStr.isNotEmpty
              ? '$startStr – $endStr'
              : '',
          'time': '${req.numberOfNights} לילות',
          'area': req.area,
          'budget': req.budget ?? '',
        },
      );

      await ds.sendMessage(
        conversationId: convoId,
        senderId: me.uid,
        senderName: me.displayName ?? me.email ?? 'מטפל',
        senderPhotoUrl: myPhotoUrl,
        text:
            '${_priceController.text.trim().isNotEmpty ? "${withShekel(_priceController.text.trim())} — " : ""}$text',
      );

      if (mounted) {
        final router = GoRouter.of(context);
        Navigator.pop(context);
        router.push('/chat/$convoId', extra: {
          'otherName': req.ownerName,
          'otherPhotoUrl': ownerPhotoUrl,
          'otherUid': req.ownerUid,
        });
      }
    } catch (_) {
      _showSnack('שגיאה בשליחת ההצעה, נסה שוב');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    const purple = AppColors.primary;
    final startStr = req.startDate != null
        ? '${req.startDate!.day.toString().padLeft(2, '0')}/${req.startDate!.month.toString().padLeft(2, '0')}'
        : '';
    final endStr = req.endDate != null
        ? '${req.endDate!.day.toString().padLeft(2, '0')}/${req.endDate!.month.toString().padLeft(2, '0')}'
        : '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text('הגש מועמדות',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.borderFaint,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: purple.withValues(alpha: 0.06),
                  border: Border.all(color: purple.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${req.petName}  ·  ${req.ownerName}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _OfferSummaryItem(
                            icon: Icons.location_on_outlined, text: req.area),
                        if (startStr.isNotEmpty && endStr.isNotEmpty)
                          _OfferSummaryItem(
                              icon: Icons.date_range_rounded,
                              text: '$startStr – $endStr'),
                        if (req.numberOfNights > 0)
                          _OfferSummaryItem(
                              icon: Icons.nights_stay_rounded,
                              text: '${req.numberOfNights} לילות'),
                        if (req.budget != null && req.budget!.isNotEmpty)
                          _OfferSummaryItem(
                              icon: Icons.account_balance_wallet_outlined,
                              text: 'תקציב: ${withShekel(req.budget!)}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _OfferInputField(
                hint: 'המחיר שלך (לדוגמה: 80₪ ללילה)',
                prefix: '₪',
                keyboardType: TextInputType.text,
                controller: _priceController,
                maxLines: 1,
              ),
              const SizedBox(height: 10),
              _OfferInputField(
                hint:
                    'לדוגמה: אני זמין בתאריכים אלה. יש לי ניסיון עם חיות כמו שלך...',
                controller: _messageController,
                maxLines: 3,
                minLines: 2,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _sending ? null : _send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: _sending
                          ? [
                              AppColors.textMuted,
                              AppColors.textSecondary,
                            ]
                          : [
                              purple,
                              AppColors.accent,
                            ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_sending)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _sending ? 'שולח...' : 'שלח הצעה',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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

/// Walk start time, or sitting drop-off (+ pickup). Null when none recorded.
String? _incomingTimeText(BookingRequest b) {
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

class _BookingInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BookingInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.labelMd
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _IconChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomingBookingsView extends ConsumerStatefulWidget {
  const _IncomingBookingsView();

  @override
  ConsumerState<_IncomingBookingsView> createState() =>
      _IncomingBookingsViewState();
}

class _IncomingBookingsViewState extends ConsumerState<_IncomingBookingsView> {
  int _tab = 0; // 0 = active, 1 = history
  final _historyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _historyScrollController.addListener(_onHistoryScroll);
  }

  @override
  void dispose() {
    _historyScrollController.dispose();
    super.dispose();
  }

  void _onHistoryScroll() {
    if (!_historyScrollController.hasClients) return;
    final maxScroll = _historyScrollController.position.maxScrollExtent;
    final currentScroll = _historyScrollController.position.pixels;
    const threshold = 200.0;
    if (maxScroll - currentScroll <= threshold) {
      ref.read(incomingBookingHistoryProvider.notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(incomingBookingsProvider);

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox_outlined,
                    size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('אין הזמנות נכנסות',
                    style: AppTextStyles.headlineSm
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('הזמנות מלקוחות יופיעו כאן',
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          );
        }
        final active = bookings.where((b) => b.isActive).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: BookingStatusToggle(
                selected: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(
              child: _tab == 0
                  ? (active.isEmpty
                      ? Center(
                          child: Text('אין הזמנות פעילות',
                              style: AppTextStyles.labelMd
                                  .copyWith(color: AppColors.textMuted)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          itemCount: active.length,
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _IncomingBookingTile(booking: active[i]),
                          ),
                        ))
                  : _IncomingHistoryTab(
                      scrollController: _historyScrollController),
            ),
          ],
        );
      },
    );
  }
}

/// Cursor-paginated "היסטוריה" tab for incoming bookings — mirrors
/// _HistoryTab in my_bookings_screen.dart for the provider side.
class _IncomingHistoryTab extends ConsumerWidget {
  final ScrollController scrollController;
  const _IncomingHistoryTab({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(incomingBookingHistoryProvider);
    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (state) {
        final history = state.bookings.where((b) => !b.isActive).toList();
        if (history.isEmpty && !state.hasMore) {
          return Center(
            child: Text('אין היסטוריית הזמנות',
                style: AppTextStyles.labelMd.copyWith(color: AppColors.textMuted)),
          );
        }
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: history.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == history.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _IncomingBookingTile(booking: history[i]),
            );
          },
        );
      },
    );
  }
}

class _IncomingBookingTile extends StatelessWidget {
  final BookingRequest booking;
  const _IncomingBookingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final isWalk = b.serviceType == BookingServiceType.walk;
    final isPending = b.status == BookingStatus.pending;
    final (label, color) = switch (b.status) {
      BookingStatus.pending => ('ממתין', AppColors.warning),
      BookingStatus.accepted => ('אושר', AppColors.success),
      BookingStatus.awaitingConfirmation => ('ממתין לאישור', AppColors.sapphire),
      BookingStatus.completed => ('הושלם', AppColors.primary),
      BookingStatus.declined => ('נדחה', AppColors.error),
      BookingStatus.cancelled => ('בוטל', AppColors.textMuted),
      BookingStatus.expired => ('פג תוקף', AppColors.textMuted),
    };

    return GestureDetector(
      onTap: () => context.push('/provider/bookings/detail', extra: b),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(
            color: isPending
                ? AppColors.warning.withValues(alpha: 0.4)
                : AppColors.border,
          ),
          boxShadow: AppShadows.subtle,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryFaint,
                  backgroundImage: (b.ownerPhotoUrl?.isNotEmpty == true)
                      ? NetworkImage(b.ownerPhotoUrl!)
                      : null,
                  child: (b.ownerPhotoUrl?.isNotEmpty != true)
                      ? Text(
                          b.ownerName.isNotEmpty
                              ? b.ownerName.characters.first.toUpperCase()
                              : '?',
                          style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.ownerName,
                          style: AppTextStyles.bodyMd
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        '${isWalk ? 'טיולים' : 'שמירה'} • ${b.petName} (${b.petType})',
                        style: AppTextStyles.labelMd
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(label,
                      style: AppTextStyles.labelMd.copyWith(
                          color: color, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_left_rounded,
                    size: 20, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 10),
            _BookingInfoRow(
              icon: Icons.calendar_today_rounded,
              text: b.formattedDateRange,
            ),
            if (_incomingTimeText(b) != null) ...[
              const SizedBox(height: 4),
              _BookingInfoRow(
                  icon: Icons.access_time_rounded,
                  text: _incomingTimeText(b)!),
            ],
            if (b.priceText?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              _BookingInfoRow(
                  icon: Icons.account_balance_wallet_outlined,
                  text: bookingPriceLabel(
                    priceText: b.priceText,
                    priceType: b.priceType,
                    hours: isWalk ? b.hours : null,
                    nights: _nightsOf(b),
                  )),
            ],
            if (b.location?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              _BookingInfoRow(
                  icon: Icons.location_on_outlined, text: b.location!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProviderToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ProviderToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? AppColors.primary : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

