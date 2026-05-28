import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';
import 'package:petpal/features/service_request/data/models/service_request_model.dart';
import 'package:petpal/features/service_request/domain/entities/service_request.dart'
    show PetSpecies;
import 'package:petpal/features/service_request/presentation/providers/service_request_provider.dart';

class ApplyServiceRequestScreen extends ConsumerStatefulWidget {
  final ServiceRequestModel request;
  const ApplyServiceRequestScreen({super.key, required this.request});

  @override
  ConsumerState<ApplyServiceRequestScreen> createState() =>
      _ApplyServiceRequestScreenState();
}

class _ApplyServiceRequestScreenState
    extends ConsumerState<ApplyServiceRequestScreen> {
  final _messageController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isSubmitting = false;
  bool _alreadyApplied = false;
  bool _checkDone = false;

  @override
  void initState() {
    super.initState();
    _checkAlreadyApplied();
  }

  Future<void> _checkAlreadyApplied() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ds = ref.read(serviceRequestDatasourceProvider);
    final has = await ds.hasApplied(widget.request.id, uid);
    if (mounted) setState(() { _alreadyApplied = has; _checkDone = true; });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final profileAsync = ref.read(currentUserProfileProvider);
    final profile = profileAsync.valueOrNull;
    final providerName = profile?.name.isNotEmpty == true
        ? profile!.name
        : user.displayName ?? user.email?.split('@').first ?? '';

    setState(() => _isSubmitting = true);
    try {
      final priceText = _priceController.text.trim();
      await ref.read(serviceRequestNotifierProvider.notifier).submitApplication(
            requestId: widget.request.id,
            providerUid: user.uid,
            providerName: providerName,
            providerPhotoUrl: profile?.photoUrl ?? user.photoURL,
            message: _messageController.text.trim().isNotEmpty
                ? _messageController.text.trim()
                : null,
            proposedPrice: priceText.isNotEmpty
                ? double.tryParse(priceText)
                : null,
          );
      if (!mounted) return;
      _snack('המועמדות הוגשה בהצלחה!');
      context.pop();
    } catch (e) {
      debugPrint('Apply error: $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _snack('שגיאה בהגשת המועמדות', isError: true);
    }
  }

  String _speciesLabel(PetSpecies s) => switch (s) {
        PetSpecies.cat => 'חתול',
        PetSpecies.rabbit => 'ארנב',
        PetSpecies.bird => 'ציפור',
        PetSpecies.other => 'אחר',
        _ => 'כלב',
      };

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final isWalk = request.serviceType.name == 'walk';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      color: AppColors.textPrimary,
                    ),
                    const Expanded(
                      child: Text(
                        'הגשת מועמדות',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    // ── Request preview card ─────────────────────────
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo with owner avatar
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20)),
                            child: SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: request.petImageUrls.isNotEmpty &&
                                            request.petImageUrls.first
                                                .isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl:
                                                request.petImageUrls.first,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(
                                                color: isWalk
                                                    ? AppColors.sapphire
                                                    : AppColors.regalNavy),
                                            errorWidget: (_, __, ___) =>
                                                Container(
                                                    color: isWalk
                                                        ? AppColors.sapphire
                                                        : AppColors.regalNavy),
                                          )
                                        : Container(
                                            color: isWalk
                                                ? AppColors.sapphire
                                                : AppColors.regalNavy,
                                            child: Center(
                                              child: Icon(
                                                isWalk
                                                    ? Icons
                                                        .directions_walk_rounded
                                                    : Icons.home_rounded,
                                                size: 64,
                                                color: Colors.white
                                                    .withValues(alpha: 0.35),
                                              ),
                                            ),
                                          ),
                                  ),
                                  if (request.ownerPhotoUrl?.isNotEmpty ==
                                      true)
                                    Positioned(
                                      bottom: 10,
                                      left: 14,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white,
                                              width: 2.5),
                                        ),
                                        child: CircleAvatar(
                                          radius: 22,
                                          backgroundColor: AppColors.surface,
                                          backgroundImage:
                                              CachedNetworkImageProvider(
                                                  request.ownerPhotoUrl!),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // Pet name + species
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 14, 16, 12),
                            child: Text(
                              '${request.petName} (${_speciesLabel(request.petSpecies)})',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),

                          const Divider(
                              height: 1,
                              thickness: 0.5,
                              color: AppColors.divider),

                          // Info rows
                          if (request.petGender != null)
                            _InfoRow(
                              icon: Icons.tune_rounded,
                              label: 'מין',
                              value: request.petGender?.name == 'female'
                                  ? 'נקבה'
                                  : 'זכר',
                            ),
                          if (isWalk && request.walkDuration != null)
                            _InfoRow(
                              icon: Icons.directions_walk_rounded,
                              label: 'משך הטיול',
                              value: request.walkDuration!,
                              iconColor: AppColors.sapphire,
                            ),
                          _InfoRow(
                            icon: Icons.location_on_rounded,
                            label: 'אזור',
                            value: request.area,
                            iconColor: AppColors.error,
                          ),
                          if (isWalk && request.walkDate != null)
                            _InfoRow(
                              icon: Icons.calendar_today_rounded,
                              label: 'תאריך',
                              value:
                                  '${request.walkDate!.day.toString().padLeft(2, '0')}/${request.walkDate!.month.toString().padLeft(2, '0')}',
                            ),
                          if (isWalk && request.walkTime != null)
                            _InfoRow(
                              icon: Icons.access_time_rounded,
                              label: 'שעה',
                              value: request.walkTime!,
                            ),
                          if (!isWalk && request.sittingStartDate != null)
                            _InfoRow(
                              icon: Icons.date_range_rounded,
                              label: 'תאריכים',
                              value:
                                  '${request.sittingStartDate!.day}/${request.sittingStartDate!.month} – ${request.sittingEndDate?.day ?? '?'}/${request.sittingEndDate?.month ?? '?'}',
                            ),
                          if (!isWalk && request.sittingLocation != null)
                            _InfoRow(
                              icon: Icons.house_siding_rounded,
                              label: 'מיקום',
                              value:
                                  request.sittingLocation?.name == 'atOwnerHome'
                                      ? 'בבית שלי'
                                      : 'בבית המטפל',
                            ),
                          if (request.budget != null)
                            _InfoRow(
                              icon: Icons.account_balance_wallet_rounded,
                              label: 'תקציב',
                              value: request.budget!,
                            ),

                          // Notes
                          if (request.specialInstructions?.isNotEmpty ==
                              true) ...[
                            const Divider(
                                height: 1,
                                thickness: 0.5,
                                color: AppColors.divider),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      request.specialInstructions!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.notes_rounded,
                                      size: 15, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'הערות',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else
                            const SizedBox(height: 6),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Already applied state ────────────────────────
                    if (_checkDone && _alreadyApplied) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFaint,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 48, color: AppColors.primary),
                            SizedBox(height: 10),
                            Text(
                              'כבר הגשת מועמדות לבקשה זו',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'תוכל/י לעקוב אחר הסטטוס תחת "המועמדויות שלי"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // ── Proposed price ───────────────────────────────
                      const Text(
                        'מחיר מוצע (אופציונלי)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AppCard(
                        padding: const EdgeInsets.all(4),
                        child: TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textDirection: TextDirection.rtl,
                          decoration: InputDecoration(
                            hintText: 'לדוגמה: 60',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(14),
                            prefixIcon: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: AppColors.primary),
                            prefixText: '₪ ',
                            prefixStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Message ──────────────────────────────────────
                      const Text(
                        'הודעה לבעל החיה (אופציונלי)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AppCard(
                        padding: const EdgeInsets.all(4),
                        child: TextField(
                          controller: _messageController,
                          textDirection: TextDirection.rtl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText:
                                'ספר/י על הניסיון שלך, למה אתה/את מתאים/ה...',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(14),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Submit ───────────────────────────────────────
                      InkWell(
                        onTap: _isSubmitting ? null : _submit,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                AppColors.primary,
                                AppColors.statusOpen,
                              ],
                            ),
                          ),
                          child: Center(
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'הגש/י מועמדות',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
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
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Icon(icon, size: 15, color: iconColor ?? AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 0.5, color: AppColors.divider),
      ],
    );
  }
}
