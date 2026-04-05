import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_input.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/petpal_scaffold.dart';
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
  Widget build(BuildContext context) {
    final startStr =
        _request.startDate != null ? _formatDate(_request.startDate!) : '';
    final endStr =
        _request.endDate != null ? _formatDate(_request.endDate!) : '';
    final nights = _request.numberOfNights;

    final chips = <Widget>[
      _DetailChip(
          icon: Icons.pets_rounded,
          label: 'שם החיה',
          value: _request.petName,
          color: const Color(0xFF7C3AED)),
      _DetailChip(
          icon: _petIcon,
          label: 'סוג',
          value: _petTypeLabel,
          color: const Color(0xFF8B5CF6)),
      if (_request.petGender != null)
        _DetailChip(
          icon: _request.petGender == PetGender.male
              ? Icons.male_rounded
              : Icons.female_rounded,
          label: 'מין',
          value: _request.petGender == PetGender.male ? 'זכר' : 'נקבה',
          color: _request.petGender == PetGender.male
              ? const Color(0xFF0EA5E9)
              : const Color(0xFFEC4899),
        ),
      if (startStr.isNotEmpty)
        _DetailChip(
            icon: Icons.calendar_today_rounded,
            label: 'תאריך התחלה',
            value: startStr,
            color: const Color(0xFFF59E0B)),
      if (endStr.isNotEmpty)
        _DetailChip(
            icon: Icons.calendar_month_rounded,
            label: 'תאריך סיום',
            value: endStr,
            color: const Color(0xFFEA580C)),
      if (nights > 0)
        _DetailChip(
            icon: Icons.nights_stay_rounded,
            label: 'מספר לילות',
            value: '$nights לילות',
            color: const Color(0xFF6366F1)),
      _DetailChip(
          icon: _request.sittingType == SittingType.atOwnerHome
              ? Icons.home_rounded
              : Icons.house_rounded,
          label: 'מיקום',
          value: _sittingTypeLabel,
          color: const Color(0xFF0D9488)),
      _DetailChip(
          icon: Icons.location_on_outlined,
          label: 'אזור',
          value: _request.area,
          color: const Color(0xFF64748B)),
      if (_request.budget != null && _request.budget!.isNotEmpty)
        _DetailChip(
            icon: Icons.account_balance_wallet_outlined,
            label: 'תשלום',
            value: _request.budget!,
            color: const Color(0xFF0F766E)),
    ];

    final showProviderCta = !_isOwner && _isOpen;

    return AppScaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            CustomScrollView(
          slivers: [
            // ── Top bar ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.07),
                                  blurRadius: 10)
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'פרטי בקשת שמירה',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A)),
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isOpen
                              ? const Color(0xFF7C3AED).withOpacity(0.12)
                              : const Color(0xFF94A3B8).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _isOpen
                                  ? const Color(0xFF7C3AED).withOpacity(0.4)
                                  : const Color(0xFF94A3B8).withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                _isOpen
                                    ? Icons.circle
                                    : Icons.check_circle_outline_rounded,
                                size: 8,
                                color: _isOpen
                                    ? const Color(0xFF7C3AED)
                                    : const Color(0xFF94A3B8)),
                            const SizedBox(width: 5),
                            Text(_isOpen ? 'פתוח' : 'הושלם',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: _isOpen
                                        ? const Color(0xFF7C3AED)
                                        : const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      if (_isOwner) ...[
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded,
                              size: 22, color: Color(0xFF64748B)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          onSelected: (value) {
                            if (value == 'edit') {
                              context.push('/sitting/edit', extra: _request);
                            } else if (value == 'delete') {
                              _delete();
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [
                                Icon(Icons.edit_outlined,
                                    size: 18, color: Color(0xFF7C3AED)),
                                SizedBox(width: 10),
                                Text('ערוך בקשה',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                              ]),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [
                                const Icon(Icons.delete_outline_rounded,
                                    size: 18, color: Color(0xFFFB7185)),
                                const SizedBox(width: 10),
                                Text('מחק בקשה',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Color(0xFFFB7185))),
                              ]),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Owner info card ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      LiveUserAvatar(
                        uid: _request.ownerUid,
                        fallbackName: _request.ownerName,
                        fallbackPhotoUrl: _request.ownerPhotoUrl,
                        size: 46,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_request.ownerName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                    fontSize: 15)),
                            Text('פורסם $_timeAgo',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Pet photo ────────────────────────────────────────────────
            if (_request.petImageUrl != null &&
                _request.petImageUrl!.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: _request.petImageUrl!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          height: 220,
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF7C3AED), strokeWidth: 2))),
                      errorWidget: (_, __, ___) => Container(
                          height: 220,
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.broken_image_rounded,
                              color: Color(0xFF94A3B8), size: 40)),
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Details chip grid ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('פרטי הבקשה',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A))),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          for (int i = 0; i < chips.length; i += 2)
                            Padding(
                              padding: EdgeInsets.only(
                                  bottom: i + 2 < chips.length ? 8 : 0),
                              child: Row(
                                children: [
                                  Expanded(child: chips[i]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: i + 1 < chips.length
                                          ? chips[i + 1]
                                          : const SizedBox()),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Special instructions ─────────────────────────────────────
            if (_request.specialInstructions != null &&
                _request.specialInstructions!.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 16, color: Color(0xFFD97706)),
                            SizedBox(width: 6),
                            Text('הוראות מיוחדות',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF92400E))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(_request.specialInstructions!,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF92400E),
                                height: 1.4)),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // ── Owner action buttons ─────────────────────────────────────
            if (_isOwner) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: _toggleStatus,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _isOpen
                            ? const Color(0xFF94A3B8).withOpacity(0.10)
                            : const Color(0xFF7C3AED).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isOpen
                              ? const Color(0xFF94A3B8).withOpacity(0.3)
                              : const Color(0xFF7C3AED).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isOpen
                                ? Icons.check_circle_outline_rounded
                                : Icons.lock_open_outlined,
                            size: 20,
                            color: _isOpen
                                ? const Color(0xFF64748B)
                                : const Color(0xFF7C3AED),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isOpen ? 'סמן כהושלם' : 'פתח מחדש',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: _isOpen
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],

            SliverToBoxAdapter(
                child: SizedBox(height: showProviderCta ? 100 : 40)),
          ],
        ),
            if (showProviderCta)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: AppButton(
                    label: 'שלח הודעה לבעלים',
                    leadingIcon: Icons.chat_bubble_outline_rounded,
                    onTap: _showOfferSheet,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
          const SizedBox(height: 3),
          Text(value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

// ── Offer bottom sheet ────────────────────────────────────────────────────────

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
          '${_priceController.text.trim().isNotEmpty ? "₪${_priceController.text.trim()} — " : ""}$text',
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
                    color: const Color(0xFFE2E8F0),
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
                        size: 20, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'הגש מועמדות',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Request summary chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
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
                            color: Color(0xFF0F172A)),
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
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
