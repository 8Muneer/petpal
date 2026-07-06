import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:petpal/core/utils/price_formatter.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/messaging/data/datasources/messaging_datasource.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';
import 'package:petpal/features/applications/domain/entities/service_application.dart';
import 'package:petpal/features/applications/presentation/providers/application_provider.dart';
import 'package:petpal/features/applications/presentation/widgets/owner_applications_list.dart';
import 'package:petpal/features/applications/presentation/widgets/service_application_sheet.dart';
import 'package:petpal/features/walks/domain/entities/walk_request.dart';
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart';

class WalkRequestDetailScreen extends ConsumerStatefulWidget {
  final WalkRequest request;

  const WalkRequestDetailScreen({required this.request, super.key});

  @override
  ConsumerState<WalkRequestDetailScreen> createState() =>
      _WalkRequestDetailScreenState();
}

class _WalkRequestDetailScreenState
    extends ConsumerState<WalkRequestDetailScreen> {
  late WalkRequest _request;
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  bool get _isOwner => _uid != null && _uid == _request.ownerUid;
  bool get _isOpen => _request.status == WalkStatus.open;
  bool get _showProviderCta => !_isOwner && _isOpen;

  void _showOfferSheet() {
    final dateStr = _request.preferredDate != null
        ? '${_request.preferredDate!.day.toString().padLeft(2, '0')}/${_request.preferredDate!.month.toString().padLeft(2, '0')}'
        : '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ServiceApplicationSheet(
        requestType: 'walk',
        requestId: _request.id,
        ownerUid: _request.ownerUid,
        ownerName: _request.ownerName,
        petName: _request.petName,
        summaryChips: [
          if (_request.area.isNotEmpty) _request.area,
          if (_request.preferredTime.isNotEmpty)
            '${_request.preferredTime}${dateStr.isNotEmpty ? '  $dateStr' : ''}',
          if (_request.budget != null && _request.budget!.isNotEmpty)
            'תקציב: ${withShekel(_request.budget!)}',
        ],
      ),
    );
  }

  Widget _buildProviderCta() {
    final uid = _uid;
    final applied = uid == null
        ? null
        : ref
            .watch(myApplicationProvider(
                (type: 'walk', id: _request.id, providerUid: uid)))
            .asData
            ?.value;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        color: Colors.white,
        child: applied != null
            ? _AppliedBadge(
                status: applied.status,
                onEdit: applied.status == ApplicationStatus.pending
                    ? _showOfferSheet
                    : null,
              )
            : GestureDetector(
                onTap: _showOfferSheet,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'הגש מועמדות',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  String get _petTypeLabel {
    switch (_request.petType) {
      case PetType.dog:
        return 'כלב';
      case PetType.cat:
        return 'חתול';
      case PetType.other:
        return 'אחר';
    }
  }


  Future<void> _toggleStatus() async {
    final newStatus = _isOpen ? WalkStatus.closed : WalkStatus.open;
    await ref.read(walkRepositoryProvider).updateRequest(
      _request.id,
      {'status': newStatus.name},
    );
    // Reflect change locally so the UI updates immediately
    setState(() {
      _request = WalkRequest(
        id: _request.id,
        ownerUid: _request.ownerUid,
        ownerName: _request.ownerName,
        ownerPhotoUrl: _request.ownerPhotoUrl,
        petName: _request.petName,
        petType: _request.petType,
        preferredDate: _request.preferredDate,
        preferredTime: _request.preferredTime,
        duration: _request.duration,
        area: _request.area,
        petImageUrl: _request.petImageUrl,
        petImageUrls: _request.petImageUrls,
        petGender: _request.petGender,
        specialInstructions: _request.specialInstructions,
        budget: _request.budget,
        status: newStatus,
        createdAt: _request.createdAt,
      );
    });
  }

  Future<void> _openMaps() async {
    final area = _request.area;
    if (area.isEmpty) return;
    final encoded = Uri.encodeComponent(area);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Opens (or creates) the 1:1 conversation with the request's owner —
  /// same flow as the chat shortcuts on the booking screens.
  Future<void> _openChat() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    final myProfile = ref.read(currentUserProfileProvider).asData?.value;
    final ds = MessagingDatasource(db: FirebaseFirestore.instance);
    final convoId = await ds.getOrCreateConversation(
      myUid: me.uid,
      myName: me.displayName ?? me.email ?? 'מטפל',
      otherUid: _request.ownerUid,
      otherName: _request.ownerName,
      myPhotoUrl: myProfile?.photoUrl ?? me.photoURL ?? '',
      otherPhotoUrl: _request.ownerPhotoUrl ?? '',
    );
    if (!mounted) return;
    context.push('/chat/$convoId', extra: {
      'otherName': _request.ownerName,
      'otherPhotoUrl': _request.ownerPhotoUrl,
      'otherUid': _request.ownerUid,
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('למחוק את הבקשה?',
              style: TextStyle(fontWeight: FontWeight.w900)),
          content: const Text('הבקשה תימחק לצמיתות.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('מחיקה',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(walkRepositoryProvider).deleteRequest(_request.id);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _request.allImages;
    final safeTop = MediaQuery.of(context).padding.top;
    final gender = _request.petGender == PetGender.male
        ? 'זכר'
        : _request.petGender == PetGender.female
            ? 'נקבה'
            : null;
    final fullDateStr = _request.preferredDate != null
        ? '${_request.preferredDate!.day.toString().padLeft(2, '0')}/${_request.preferredDate!.month.toString().padLeft(2, '0')}'
        : '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // ── Hero photo ────────────────────────────────────────────────────────
            Positioned.fill(
              bottom: MediaQuery.of(context).size.height * 0.42,
              child: images.isEmpty
                  ? _WalkHeroBg(petType: _request.petType)
                  : images.length == 1
                      ? CachedNetworkImage(
                          imageUrl: images.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              _WalkHeroBg(petType: _request.petType),
                          errorWidget: (_, __, ___) =>
                              _WalkHeroBg(petType: _request.petType),
                        )
                      : Stack(
                          children: [
                            PageView.builder(
                              controller: _pageCtrl,
                              onPageChanged: (i) =>
                                  setState(() => _page = i),
                              itemCount: images.length,
                              itemBuilder: (_, i) => CachedNetworkImage(
                                imageUrl: images[i],
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    _WalkHeroBg(petType: _request.petType),
                                errorWidget: (_, __, ___) =>
                                    _WalkHeroBg(petType: _request.petType),
                              ),
                            ),
                            // Left arrow → next image (RTL)
                            if (_page < images.length - 1)
                              Positioned(
                                left: 12,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () => _pageCtrl.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    ),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.chevron_left_rounded,
                                          color: Colors.white,
                                          size: 26),
                                    ),
                                  ),
                                ),
                              ),
                            // Right arrow → previous image (RTL)
                            if (_page > 0)
                              Positioned(
                                right: 12,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () => _pageCtrl.previousPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    ),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.white,
                                          size: 26),
                                    ),
                                  ),
                                ),
                              ),
                            // Dot indicators
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  images.length,
                                  (i) => AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    width: _page == i ? 18 : 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    decoration: BoxDecoration(
                                      color: _page == i
                                          ? Colors.white
                                          : Colors.white
                                              .withValues(alpha: 0.5),
                                      borderRadius:
                                          BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
            ),

            // ── White info sheet ──────────────────────────────────────────────────
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: 0.56,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Pet thumbnail (top-left corner, overlapping hero)
                      if (images.isNotEmpty)
                        Positioned(
                          top: -36,
                          left: 20,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 12)
                              ],
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: images.first,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      // Content
                      SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                            20,
                            images.isNotEmpty ? 48 : 24,
                            20,
                            _showProviderCta ? 110 : 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name + breed row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _request.petName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '($_petTypeLabel)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // ── Organized info grid ──────────────────────
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  if (gender != null) ...[
                                    _InfoRow(
                                      icon: Icons.transgender_rounded,
                                      label: 'מין',
                                      value: gender,
                                      valueColor:
                                          _request.petGender ==
                                                  PetGender.female
                                              ? AppColors.error
                                              : AppColors.smartBlue,
                                    ),
                                    const _InfoDivider(),
                                  ],
                                  _InfoRow(
                                    icon: Icons.timer_rounded,
                                    label: 'משך הטיול',
                                    value: _request.duration,
                                    valueColor: AppColors.primary,
                                  ),
                                  const _InfoDivider(),
                                  _InfoRow(
                                    icon: Icons.location_on_rounded,
                                    label: 'אזור',
                                    value: _request.area,
                                    valueColor: AppColors.error,
                                  ),
                                  if (fullDateStr.isNotEmpty) ...[
                                    const _InfoDivider(),
                                    _InfoRow(
                                      icon: Icons.calendar_today_rounded,
                                      label: 'תאריך',
                                      value: fullDateStr,
                                      valueColor: AppColors.regalNavy,
                                    ),
                                  ],
                                  if (_request.preferredTime.isNotEmpty) ...[
                                    const _InfoDivider(),
                                    _InfoRow(
                                      icon: Icons.access_time_rounded,
                                      label: 'שעה',
                                      value: _request.preferredTime,
                                      valueColor: AppColors.success,
                                    ),
                                  ],
                                  if (_request.budget != null &&
                                      _request.budget!.isNotEmpty) ...[
                                    const _InfoDivider(),
                                    _InfoRow(
                                      icon: Icons
                                          .account_balance_wallet_outlined,
                                      label: 'תקציב',
                                      value: withShekel(_request.budget!),
                                      valueColor:
                                          AppColors.smartBlue,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!_isOwner) ...[
                              const SizedBox(height: 22),
                              // Owner label
                              const Text(
                                'בעל החיה',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Owner row
                              Row(
                                children: [
                                  LiveUserAvatar(
                                    uid: _request.ownerUid,
                                    fallbackName: _request.ownerName,
                                    fallbackPhotoUrl:
                                        _request.ownerPhotoUrl,
                                    size: 42,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _request.ownerName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  _CircleAction(
                                    icon: Icons.map_rounded,
                                    color: AppColors.error,
                                    onTap: _openMaps,
                                  ),
                                  const SizedBox(width: 8),
                                  _CircleAction(
                                    icon: Icons
                                        .chat_bubble_outline_rounded,
                                    color: AppColors.primary,
                                    onTap: _openChat,
                                  ),
                                ],
                              ),
                            ],
                            // Notes / special instructions
                            if (_request.specialInstructions != null &&
                                _request
                                    .specialInstructions!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  border: Border.all(
                                      color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                            Icons
                                                .sticky_note_2_outlined,
                                            size: 15,
                                            color: AppColors.warning),
                                        SizedBox(width: 6),
                                        Text(
                                          'הערות',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w800,
                                              color:
                                                  AppColors.warning),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _request.specialInstructions!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // Offers received (owner only)
                            if (_isOwner) ...[
                              const SizedBox(height: 22),
                              OwnerApplicationsList(
                                requestType: 'walk',
                                requestId: _request.id,
                              ),
                            ],
                            // Owner controls
                            if (_isOwner) ...[
                              const SizedBox(height: 22),
                              GestureDetector(
                                onTap: _toggleStatus,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  decoration: BoxDecoration(
                                    color: _isOpen
                                        ? AppColors.textMuted
                                            .withValues(alpha: 0.10)
                                        : AppColors.statusOpen
                                            .withValues(alpha: 0.10),
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _isOpen
                                          ? AppColors.textMuted
                                              .withValues(alpha: 0.3)
                                          : AppColors.statusOpen
                                              .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isOpen
                                            ? Icons
                                                .check_circle_outline_rounded
                                            : Icons.lock_open_outlined,
                                        size: 20,
                                        color: _isOpen
                                            ? AppColors.textSecondary
                                            : AppColors.success,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isOpen
                                            ? 'סמן כהושלם'
                                            : 'פתח מחדש',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: _isOpen
                                              ? AppColors.textSecondary
                                              : AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Floating back button ───────────────────────────────────────────
            Positioned(
              top: safeTop + 12,
              left: 16,
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8)
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      size: 18, color: AppColors.textPrimary),
                ),
              ),
            ),

            // ── Owner menu ───────────────────────────────────────────────────────
            if (_isOwner)
              Positioned(
                top: safeTop + 8,
                right: 12,
                child: PopupMenuButton<String>(
                  icon: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8)
                      ],
                    ),
                    child: const Icon(Icons.more_vert_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  onSelected: (v) {
                    if (v == 'edit') {
                      context.push('/walks/edit', extra: _request);
                    } else if (v == 'delete') {
                      _delete();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined,
                            size: 18, color: AppColors.primary),
                        SizedBox(width: 10),
                        Text('ערוך בקשה',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.error),
                        SizedBox(width: 10),
                        Text('מחק בקשה',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.error)),
                      ]),
                    ),
                  ],
                ),
              ),

            // ── Provider CTA ───────────────────────────────────────────────────────
            if (_showProviderCta) _buildProviderCta(),
          ],
        ),
      ),
    );
  }
}

// ── Hero bg ────────────────────────────────────────────────────────────────
class _WalkHeroBg extends StatelessWidget {
  final PetType petType;
  const _WalkHeroBg({required this.petType});
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.prussianBlue, AppColors.smartBlue],
          ),
        ),
        child: Center(
          child: Icon(
            petType == PetType.dog
                ? Icons.directions_walk_rounded
                : Icons.pets_rounded,
            size: 100,
            color: Colors.white.withValues(alpha: 0.30),
          ),
        ),
      );
}

// ── Info row ───────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 16, color: valueColor.withValues(alpha: 0.6)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor.withValues(alpha: 0.65),
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ],
        ),
      );
}

// ── Info divider ───────────────────────────────────────────────────────────
class _InfoDivider extends StatelessWidget {
  const _InfoDivider();
  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.border,
      );
}

// ── Circle action button ──────────────────────────────────────────────────
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleAction(
      {required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      );
}

// ── Applied badge (provider already submitted an offer) ──────────────────────
class _AppliedBadge extends StatelessWidget {
  final ApplicationStatus status;
  final VoidCallback? onEdit;
  const _AppliedBadge({required this.status, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      ApplicationStatus.pending => (
          'הגשת הצעה — ממתין לאישור',
          AppColors.warning,
          Icons.hourglass_top_rounded
        ),
      ApplicationStatus.accepted => (
          'ההצעה שלך אושרה',
          AppColors.success,
          Icons.check_circle_rounded
        ),
      ApplicationStatus.refused => (
          'ההצעה שלך נדחתה',
          AppColors.error,
          Icons.cancel_rounded
        ),
    };

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900)),
          ),
          if (onEdit != null)
            TextButton(
              onPressed: onEdit,
              child: const Text('ערוך'),
            ),
        ],
      ),
    );
  }
}
