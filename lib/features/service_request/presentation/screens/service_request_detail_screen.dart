import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/features/service_request/data/models/application_model.dart';
import 'package:petpal/features/service_request/data/models/service_request_model.dart';
import 'package:petpal/features/service_request/domain/entities/service_request.dart';
import 'package:petpal/features/service_request/presentation/providers/service_request_provider.dart';

class ServiceRequestDetailScreen extends ConsumerWidget {
  final ServiceRequestModel request;
  const ServiceRequestDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync =
        ref.watch(requestApplicationsProvider(request.id));
    final isOpen = request.status == ServiceRequestStatus.open;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ───────────────────────────────────────────────
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
                        'פרטי הבקשה',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _StatusChip(status: request.status),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    // ── Request summary card ──────────────────────────
                    _RequestSummaryCard(request: request),

                    const SizedBox(height: 20),

                    // ── Applicants section ────────────────────────────
                    Row(
                      children: [
                        const Text(
                          'מועמדים',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (request.applicationCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryFaint,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${request.applicationCount}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    applicationsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      ),
                      error: (e, _) =>
                          Center(child: Text('שגיאה בטעינת מועמדים: $e')),
                      data: (apps) {
                        if (apps.isEmpty) {
                          return _EmptyApplicants(isOpen: isOpen);
                        }
                        return Column(
                          children: apps
                              .map((app) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12),
                                    child: _ApplicantCard(
                                      application: app,
                                      requestId: request.id,
                                      isRequestOpen: isOpen,
                                    ),
                                  ))
                              .toList(),
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
}

// ── Request summary card ──────────────────────────────────────────────────────

class _RequestSummaryCard extends StatelessWidget {
  final ServiceRequestModel request;
  const _RequestSummaryCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final isWalk = request.serviceType.name == 'walk';

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo with owner avatar ───────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: request.petImageUrls.isNotEmpty &&
                            request.petImageUrls.first.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: request.petImageUrls.first,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: isWalk
                                    ? AppColors.sapphire
                                    : AppColors.regalNavy),
                            errorWidget: (_, __, ___) => Container(
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
                                    ? Icons.directions_walk_rounded
                                    : Icons.home_rounded,
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                  ),
                  if (request.ownerPhotoUrl?.isNotEmpty == true)
                    Positioned(
                      bottom: 10,
                      left: 14,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.surface,
                          backgroundImage: CachedNetworkImageProvider(
                              request.ownerPhotoUrl!),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Pet name + species ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Text(
              '${request.petName} (${_speciesLabel(request.petSpecies)})',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          const Divider(height: 1, thickness: 0.5, color: AppColors.divider),

          // ── Info rows ─────────────────────────────────────────────────
          if (request.petGender != null)
            _SummaryRow(
              icon: Icons.tune_rounded,
              label: 'מין',
              value: request.petGender?.name == 'female' ? 'נקבה' : 'זכר',
            ),
          if (isWalk && request.walkDuration != null)
            _SummaryRow(
              icon: Icons.directions_walk_rounded,
              label: 'משך הטיול',
              value: request.walkDuration!,
              iconColor: AppColors.sapphire,
            ),
          _SummaryRow(
            icon: Icons.location_on_rounded,
            label: 'אזור',
            value: request.area,
            iconColor: AppColors.error,
          ),
          if (isWalk && request.walkDate != null)
            _SummaryRow(
              icon: Icons.calendar_today_rounded,
              label: 'תאריך',
              value:
                  '${request.walkDate!.day.toString().padLeft(2, '0')}/${request.walkDate!.month.toString().padLeft(2, '0')}/${request.walkDate!.year}',
            ),
          if (isWalk && request.walkTime != null)
            _SummaryRow(
              icon: Icons.access_time_rounded,
              label: 'שעה',
              value: request.walkTime!,
            ),
          if (!isWalk && request.sittingStartDate != null)
            _SummaryRow(
              icon: Icons.date_range_rounded,
              label: 'תאריכים',
              value:
                  '${request.sittingStartDate!.day}/${request.sittingStartDate!.month} – ${request.sittingEndDate?.day ?? '?'}/${request.sittingEndDate?.month ?? '?'}',
            ),
          if (!isWalk && request.sittingLocation != null)
            _SummaryRow(
              icon: Icons.house_siding_rounded,
              label: 'מיקום',
              value: request.sittingLocation == SittingLocation.atOwnerHome
                  ? 'בבית שלי'
                  : 'בבית המטפל',
            ),
          if (request.budget != null)
            _SummaryRow(
              icon: Icons.account_balance_wallet_rounded,
              label: 'תקציב',
              value: request.budget!,
            ),

          // ── Notes ─────────────────────────────────────────────────────
          if (request.specialInstructions?.isNotEmpty == true) ...[
            const Divider(height: 1, thickness: 0.5, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
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
    );
  }

  String _speciesLabel(PetSpecies s) => switch (s) {
        PetSpecies.cat => 'חתול',
        PetSpecies.rabbit => 'ארנב',
        PetSpecies.bird => 'ציפור',
        PetSpecies.other => 'אחר',
        _ => 'כלב',
      };
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _SummaryRow({
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

// ── Applicant card ────────────────────────────────────────────────────────────

class _ApplicantCard extends ConsumerWidget {
  final ApplicationModel application;
  final String requestId;
  final bool isRequestOpen;

  const _ApplicantCard({
    required this.application,
    required this.requestId,
    required this.isRequestOpen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = application.isPending;
    final isAccepted = application.isAccepted;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider info row
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surface,
                backgroundImage:
                    application.providerPhotoUrl?.isNotEmpty == true
                        ? CachedNetworkImageProvider(
                            application.providerPhotoUrl!)
                        : null,
                child: application.providerPhotoUrl?.isEmpty != false
                    ? const Icon(Icons.person_rounded,
                        size: 20, color: AppColors.textMuted)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.providerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (application.proposedPrice != null)
                      Text(
                        '₪${application.proposedPrice!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              // Application status badge
              if (isAccepted)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'התקבל',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                )
              else if (!isPending)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'נדחה',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),

          if (application.message?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                application.message!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],

          // Accept / Reject — only when request is open and application is pending
          if (isRequestOpen && isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'קבל',
                    icon: Icons.check_rounded,
                    color: AppColors.success,
                    onTap: () => _accept(context, ref),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'דחה',
                    icon: Icons.close_rounded,
                    color: AppColors.error,
                    onTap: () => _reject(context, ref),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirmDialog(
      context,
      title: 'קבלת מועמד',
      body:
          'האם לקבל את ${application.providerName}? שאר המועמדים יידחו אוטומטית.',
      confirmLabel: 'כן, קבל',
      confirmColor: AppColors.success,
    );
    if (!confirmed) return;
    await ref
        .read(serviceRequestNotifierProvider.notifier)
        .acceptApplication(
          requestId: requestId,
          applicationId: application.id,
        );
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirmDialog(
      context,
      title: 'דחיית מועמד',
      body: 'האם לדחות את ${application.providerName}?',
      confirmLabel: 'דחה',
      confirmColor: AppColors.error,
    );
    if (!confirmed) return;
    await ref
        .read(serviceRequestNotifierProvider.notifier)
        .rejectApplication(
          requestId: requestId,
          applicationId: application.id,
        );
  }

  Future<bool> _confirmDialog(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w900)),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ביטול'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  TextButton.styleFrom(foregroundColor: confirmColor),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ),
    );
    return result == true;
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final ServiceRequestStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ServiceRequestStatus.open => ('פתוח', AppColors.success),
      ServiceRequestStatus.booked => ('הוזמן', AppColors.primary),
      ServiceRequestStatus.completed => ('הושלם', AppColors.textMuted),
      ServiceRequestStatus.cancelled => ('בוטל', AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyApplicants extends StatelessWidget {
  final bool isOpen;
  const _EmptyApplicants({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            isOpen ? Icons.hourglass_empty_rounded : Icons.people_outline_rounded,
            size: 56,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            isOpen ? 'ממתין למועמדים...' : 'אין מועמדים',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textSecondary,
            ),
          ),
          if (isOpen) ...[
            const SizedBox(height: 6),
            const Text(
              'ספקי שירות יראו את הבקשה שלך ויוכלו להגיש מועמדות',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
