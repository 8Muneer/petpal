import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:petpal/core/utils/price_formatter.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/messaging/data/datasources/messaging_datasource.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';

class SittingRequestDetailScreen extends ConsumerStatefulWidget {
  final SittingRequest request;

  const SittingRequestDetailScreen({required this.request, super.key});

  @override
  ConsumerState<SittingRequestDetailScreen> createState() =>
      _SittingRequestDetailScreenState();
}

class _SittingRequestDetailScreenState
    extends ConsumerState<SittingRequestDetailScreen> {
  late SittingRequest _request;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  bool get _isOwner => _uid != null && _uid == _request.ownerUid;
  bool get _isOpen => _request.status == SittingStatus.open;

  IconData get _petIcon {
    switch (_request.petType) {
      case PetType.dog:
        return Icons.directions_walk_rounded;
      case PetType.cat:
        return Icons.pets_rounded;
      case PetType.other:
        return Icons.cruelty_free_rounded;
    }
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

  String get _sittingTypeLabel {
    switch (_request.sittingType) {
      case SittingType.atOwnerHome:
        return 'בבית הבעלים';
      case SittingType.atSitterHome:
        return 'בבית השומר/ת';
    }
  }

  String get _timeAgo {
    if (_request.createdAt == null) return '';
    final diff = DateTime.now().difference(_request.createdAt!);
    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק׳';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
    if (diff.inDays < 7) return 'לפני ${diff.inDays} ימים';
    return '${_request.createdAt!.day}/${_request.createdAt!.month}/${_request.createdAt!.year}';
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _showOfferSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SittingOfferBottomSheet(request: _request),
    );
  }

  Future<void> _toggleStatus() async {
    final newStatus =
        _isOpen ? SittingStatus.closed : SittingStatus.open;
    await ref.read(sittingRepositoryProvider).updateRequest(
      _request.id,
      {'status': newStatus.name},
    );
    setState(() {
      _request = SittingRequest(
        id: _request.id,
        ownerUid: _request.ownerUid,
        ownerName: _request.ownerName,
        ownerPhotoUrl: _request.ownerPhotoUrl,
        petName: _request.petName,
        petType: _request.petType,
        petGender: _request.petGender,
        petImageUrl: _request.petImageUrl,
        startDate: _request.startDate,
        endDate: _request.endDate,
        sittingType: _request.sittingType,
        area: _request.area,
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
                backgroundColor: const Color(0xFFFB7185),
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
      await ref.read(sittingRepositoryProvider).deleteRequest(_request.id);
      if (mounted) context.pop();
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final hasPetPhoto =
        _request.petImageUrl != null && _request.petImageUrl!.isNotEmpty;
    final safeTop = MediaQuery.of(context).padding.top;
    final showProviderCta = !_isOwner && _isOpen;
    final startStr =
        _request.startDate != null ? _formatDate(_request.startDate!) : '';
    final endStr =
        _request.endDate != null ? _formatDate(_request.endDate!) : '';
    final nights = _request.numberOfNights;
    final gender = _request.petGender == PetGender.male
        ? 'זכר'
        : _request.petGender == PetGender.female
            ? 'נקבה'
            : null;
    const purple = Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: const Color(0xFFF3EEFF),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // ── Hero photo ────────────────────────────────────────────────────────
            Positioned.fill(
              bottom: MediaQuery.of(context).size.height * 0.42,
              child: hasPetPhoto
                  ? CachedNetworkImage(
                      imageUrl: _request.petImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          _SittingHeroBg(petType: _request.petType),
                      errorWidget: (_, __, ___) =>
                          _SittingHeroBg(petType: _request.petType),
                    )
                  : _SittingHeroBg(petType: _request.petType),
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
                      // Pet thumbnail
                      if (hasPetPhoto)
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
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 12)
                              ],
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: _request.petImageUrl!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      // Content
                      SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                            20,
                            hasPetPhoto ? 48 : 24,
                            20,
                            showProviderCta ? 110 : 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name + breed
                            Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.baseline,
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
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                children: [
                                  if (gender != null) ...[
                                    _SInfoRow(
                                      icon: Icons.transgender_rounded,
                                      label: 'מין',
                                      value: gender,
                                      valueColor:
                                          _request.petGender ==
                                                  PetGender.female
                                              ? const Color(0xFFEC4899)
                                              : const Color(0xFF0EA5E9),
                                    ),
                                    const _SInfoDivider(),
                                  ],
                                  _SInfoRow(
                                    icon: Icons.location_on_rounded,
                                    label: 'אזור',
                                    value: _request.area,
                                    valueColor: const Color(0xFFEF4444),
                                  ),
                                  if (startStr.isNotEmpty) ...[
                                    const _SInfoDivider(),
                                    _SInfoRow(
                                      icon: Icons.calendar_today_rounded,
                                      label: 'תאריך התחלה',
                                      value: startStr,
                                      valueColor: const Color(0xFF0891B2),
                                    ),
                                  ],
                                  if (endStr.isNotEmpty) ...[
                                    const _SInfoDivider(),
                                    _SInfoRow(
                                      icon: Icons.event_rounded,
                                      label: 'תאריך סיום',
                                      value: endStr,
                                      valueColor: const Color(0xFF059669),
                                    ),
                                  ],
                                  if (nights > 0) ...[
                                    const _SInfoDivider(),
                                    _SInfoRow(
                                      icon: Icons.nights_stay_rounded,
                                      label: 'מספר לילות',
                                      value: '$nights לילות',
                                      valueColor:
                                          const Color(0xFF6366F1),
                                    ),
                                  ],
                                  const _SInfoDivider(),
                                  _SInfoRow(
                                    icon: _request.sittingType ==
                                            SittingType.atOwnerHome
                                        ? Icons.home_rounded
                                        : Icons.house_rounded,
                                    label: 'מיקום השמירה',
                                    value: _sittingTypeLabel,
                                    valueColor:
                                        const Color(0xFF0D9488),
                                  ),
                                  if (_request.budget != null &&
                                      _request.budget!.isNotEmpty) ...[
                                    const _SInfoDivider(),
                                    _SInfoRow(
                                      icon: Icons
                                          .account_balance_wallet_outlined,
                                      label: 'תקציב',
                                      value: withShekel(_request.budget!),
                                      valueColor: purple,
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
                                        color: purple,
                                      ),
                                    ),
                                  ),
                                  _SittingCircleAction(
                                    icon: Icons.map_rounded,
                                    color: const Color(0xFFEF4444),
                                    onTap: _openMaps,
                                  ),
                                  const SizedBox(width: 8),
                                  _SittingCircleAction(
                                    icon: Icons
                                        .chat_bubble_outline_rounded,
                                    color: purple,
                                    onTap: () {},
                                  ),
                                ],
                              ),
                            ],
                            // Notes
                            if (_request.specialInstructions != null &&
                                _request.specialInstructions!
                                    .isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  border: Border.all(
                                      color: const Color(0xFFFED7AA)),
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
                                            color: Color(0xFFF97316)),
                                        SizedBox(width: 6),
                                        Text(
                                          'הערות',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w800,
                                              color:
                                                  Color(0xFFF97316)),
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
                                            .withOpacity(0.10)
                                        : AppColors.statusOpen
                                            .withOpacity(0.10),
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _isOpen
                                          ? AppColors.textMuted
                                              .withOpacity(0.3)
                                          : AppColors.statusOpen
                                              .withOpacity(0.3),
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
                                            : const Color(0xFF16A34A),
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
                                              : const Color(0xFF16A34A),
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
                    color: Colors.white.withOpacity(0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8)
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      size: 18, color: AppColors.textPrimary),
                ),
              ),
            ),

            // ── Owner menu ─────────────────────────────────────────────────────
            if (_isOwner)
              Positioned(
                top: safeTop + 8,
                right: 12,
                child: PopupMenuButton<String>(
                  icon: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8)
                      ],
                    ),
                    child: const Icon(Icons.more_vert_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  onSelected: (v) {
                    if (v == 'edit')
                      context.push('/sitting/edit', extra: _request);
                    else if (v == 'delete') _delete();
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
                            size: 18, color: Color(0xFFFB7185)),
                        SizedBox(width: 10),
                        Text('מחק בקשה',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFFFB7185))),
                      ]),
                    ),
                  ],
                ),
              ),

            // ── Provider CTA ───────────────────────────────────────────────────────
            if (showProviderCta)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  color: Colors.white,
                  child: GestureDetector(
                    onTap: _showOfferSheet,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [purple, Color(0xFFA78BFA)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: purple.withOpacity(0.35),
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
              ),
          ],
        ),
      ),
    );
  }
}

// ── Hero bg ────────────────────────────────────────────────────────────────
class _SittingHeroBg extends StatelessWidget {
  final PetType petType;
  const _SittingHeroBg({required this.petType});
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          ),
        ),
        child: Center(
          child: Icon(
            petType == PetType.dog
                ? Icons.directions_walk_rounded
                : Icons.pets_rounded,
            size: 100,
            color: Colors.white.withOpacity(0.30),
          ),
        ),
      );
}

// ── Info row ───────────────────────────────────────────────────────────────
class _SInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  const _SInfoRow({
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
            Icon(icon, size: 16, color: valueColor.withOpacity(0.6)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor.withOpacity(0.65),
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
class _SInfoDivider extends StatelessWidget {
  const _SInfoDivider();
  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFE2E8F0),
      );
}

// ── Circle action button ──────────────────────────────────────────────────
class _SittingCircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SittingCircleAction(
      {required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      );
}

// ── Hero gradient background ─────────────────────────────────────────────
class _SittingOfferBottomSheet extends ConsumerStatefulWidget {
  final SittingRequest request;
  const _SittingOfferBottomSheet({required this.request});

  @override
  ConsumerState<_SittingOfferBottomSheet> createState() =>
      _SittingOfferBottomSheetState();
}

class _SittingOfferBottomSheetState
    extends ConsumerState<_SittingOfferBottomSheet> {
  final _messageController = TextEditingController();
  final _priceController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    setState(() => _sending = true);

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

    String fmtDate(DateTime? d) => d != null
        ? '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}'
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
        'startDate': fmtDate(req.startDate),
        'endDate': fmtDate(req.endDate),
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
      router.push('/chat/$convoId', extra: {'otherName': req.ownerName, 'otherPhotoUrl': ownerPhotoUrl, 'otherUid': req.ownerUid});
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;

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
              // Handle + title + close
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'הגש מועמדות',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Request summary chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.borderFaint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.home_rounded,
                        size: 15, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${req.ownerName} · ${req.petName}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Price field
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'מחיר מוצע (₪)',
                  hintStyle: const TextStyle(
                      color: Color(0xFFCBD5E1), fontSize: 14),
                  prefixText: '₪ ',
                  prefixStyle: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
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
                    borderSide: const BorderSide(
                        color: Color(0xFF7C3AED), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Message field
              TextField(
                controller: _messageController,
                maxLines: 3,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'כתוב הודעה לבעל החיה...',
                  hintStyle: const TextStyle(
                      color: Color(0xFFCBD5E1), fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
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
                    borderSide: const BorderSide(
                        color: Color(0xFF7C3AED), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Send button
              AppButton(
                label: 'שלח הצעה',
                leadingIcon: Icons.send_rounded,
                isLoading: _sending,
                onTap: _sending ? null : _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
