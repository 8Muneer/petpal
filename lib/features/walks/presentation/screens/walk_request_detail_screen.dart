import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/petpal_scaffold.dart';
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

  @override
  void initState() {
    super.initState();
    _request = widget.request;
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  bool get _isOwner => _uid != null && _uid == _request.ownerUid;
  bool get _isOpen => _request.status == WalkStatus.open;

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

  String get _timeAgo {
    if (_request.createdAt == null) return '';
    final diff = DateTime.now().difference(_request.createdAt!);
    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק׳';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
    if (diff.inDays < 7) return 'לפני ${diff.inDays} ימים';
    return '${_request.createdAt!.day}/${_request.createdAt!.month}/${_request.createdAt!.year}';
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
        petGender: _request.petGender,
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
      await ref.read(walkRepositoryProvider).deleteRequest(_request.id);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullDateStr = _request.preferredDate != null
        ? '${_request.preferredDate!.day.toString().padLeft(2, '0')}/${_request.preferredDate!.month.toString().padLeft(2, '0')}/${_request.preferredDate!.year}'
        : '';

    final chips = <Widget>[
      // Pet identity
      _DetailChip(
          icon: Icons.pets_rounded,
          label: 'שם החיה',
          value: _request.petName,
          color: const Color(0xFF0EA5E9)),
      _DetailChip(
          icon: _petIcon,
          label: 'סוג',
          value: _petTypeLabel,
          color: const Color(0xFF0F766E)),
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
      // Date + time (always adjacent)
      if (fullDateStr.isNotEmpty)
        _DetailChip(
            icon: Icons.calendar_today_rounded,
            label: 'תאריך',
            value: fullDateStr,
            color: const Color(0xFFF59E0B)),
      _DetailChip(
          icon: Icons.access_time_rounded,
          label: 'שעת פגישה',
          value: _request.preferredTime,
          color: const Color(0xFFEA580C)),
      _DetailChip(
          icon: Icons.timer_outlined,
          label: 'משך טיול',
          value: _request.duration,
          color: const Color(0xFF0D9488)),
      // Location + payment
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
            color: const Color(0xFF8B5CF6)),
    ];

    return PetPalScaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          slivers: [
            // ── Top bar ─────────────────────────────────────────────────
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
                          'פרטי בקשת טיול',
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
                              ? const Color(0xFF22C55E).withOpacity(0.12)
                              : const Color(0xFF94A3B8).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _isOpen
                                  ? const Color(0xFF22C55E).withOpacity(0.4)
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
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFF94A3B8)),
                            const SizedBox(width: 5),
                            Text(_isOpen ? 'פתוח' : 'הושלם',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: _isOpen
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      // ⋮ owner actions menu
                      if (_isOwner) ...[
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded,
                              size: 22, color: Color(0xFF64748B)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          onSelected: (value) {
                            if (value == 'edit') {
                              context.push('/walks/edit', extra: _request);
                            } else if (value == 'delete') {
                              _delete();
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [
                                Icon(Icons.edit_outlined,
                                    size: 18, color: Color(0xFF0F766E)),
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
                child: GlassCard(
                  useBlur: true,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: _request.ownerPhotoUrl != null &&
                                  _request.ownerPhotoUrl!.isNotEmpty
                              ? null
                              : const LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Color(0xFF0F766E),
                                    Color(0xFF22C55E)
                                  ],
                                ),
                          image: _request.ownerPhotoUrl != null &&
                                  _request.ownerPhotoUrl!.isNotEmpty
                              ? DecorationImage(
                                  image:
                                      NetworkImage(_request.ownerPhotoUrl!),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: _request.ownerPhotoUrl != null &&
                                _request.ownerPhotoUrl!.isNotEmpty
                            ? null
                            : Center(
                                child: Text(
                                  _request.ownerName.isNotEmpty
                                      ? _request.ownerName.characters.first
                                          .toUpperCase()
                                      : 'P',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16),
                                ),
                              ),
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

            // ── Pet photo (large) ────────────────────────────────────────
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
                                  color: Color(0xFF0F766E), strokeWidth: 2))),
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
                child: GlassCard(
                  useBlur: true,
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
                  child: Column(
                    children: [
                      // Status toggle
                      GestureDetector(
                        onTap: _toggleStatus,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _isOpen
                                ? const Color(0xFF94A3B8).withOpacity(0.10)
                                : const Color(0xFF22C55E).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isOpen
                                  ? const Color(0xFF94A3B8).withOpacity(0.3)
                                  : const Color(0xFF22C55E).withOpacity(0.3),
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
                                    : const Color(0xFF16A34A),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isOpen ? 'סמן כהושלם' : 'פתח מחדש',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: _isOpen
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ── Two-line colored chip ─────────────────────────────────────────────────────
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
                      fontSize: 10, fontWeight: FontWeight.w700, color: color)),
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
