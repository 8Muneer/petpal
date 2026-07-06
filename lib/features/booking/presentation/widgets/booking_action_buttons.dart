import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';
import 'package:petpal/features/booking/presentation/providers/booking_provider.dart';

/// Status-driven action bar for an incoming booking: accept/decline while
/// pending, mark-complete/cancel while accepted, and a waiting banner while
/// awaiting the owner's completion confirmation. Shared by the incoming
/// bookings list tile and the booking detail screen so the accept/decline/
/// complete/cancel logic lives in exactly one place.
class BookingActionButtons extends ConsumerStatefulWidget {
  final BookingRequest booking;
  const BookingActionButtons({required this.booking, super.key});

  @override
  ConsumerState<BookingActionButtons> createState() =>
      _BookingActionButtonsState();
}

class _BookingActionButtonsState extends ConsumerState<BookingActionButtons> {
  bool _loading = false;

  Future<void> _updateStatus(BookingStatus status, {String? note}) async {
    setState(() => _loading = true);
    try {
      await ref
          .read(bookingRepositoryProvider)
          .updateBookingStatus(widget.booking.id, status, providerNote: note);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה בעדכון הבקשה, נסה שוב'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDeclineDialog() async {
    final noteCtrl = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('דחיית הזמנה'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('האם לדחות את הבקשה?'),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    hintText: 'הסבר (אופציונלי)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
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
                child: const Text('דחה'),
              ),
            ],
          ),
        ),
      );
      if (confirmed == true && mounted) {
        await _updateStatus(BookingStatus.declined,
            note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
      }
    } finally {
      noteCtrl.dispose();
    }
  }

  Future<void> _cancelByProvider() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('ביטול הזמנה'),
          content: const Text(
            'לבטל את ההזמנה שאישרת? פעולה זו אינה ניתנת לשחזור ובעל החיה יקבל על כך הודעה.',
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
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(bookingRepositoryProvider)
          .cancelBookingByProvider(widget.booking.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה בביטול ההזמנה, נסה שוב'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestCompletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('סיום השירות'),
          content: const Text(
            'נשלח לבעל החיה בקשה לאשר שהשירות הושלם. לאחר אישורו הוא יוכל לדרג אותך. להמשיך?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: const Text('שלח לאישור'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) {
      await _updateStatus(BookingStatus.awaitingConfirmation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final isPending = b.status == BookingStatus.pending;
    final isAccepted = b.status == BookingStatus.accepted;
    final isAwaitingConfirmation =
        b.status == BookingStatus.awaitingConfirmation;

    if (!isPending && !isAccepted && !isAwaitingConfirmation) {
      return const SizedBox.shrink();
    }

    if (_loading) {
      return const Center(
        child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (isPending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _showDeclineDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('דחה'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(BookingStatus.accepted),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('אשר'),
            ),
          ),
        ],
      );
    }

    if (isAccepted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (b.serviceDateReached)
            ElevatedButton.icon(
              onPressed: _requestCompletion,
              icon: const Icon(Icons.task_alt_rounded, size: 16),
              label: const Text('סיימתי את השירות'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_rounded,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ניתן לסמן סיום החל מ-${b.completionAvailableFromLabel}',
                      style: AppTextStyles.labelMd
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _cancelByProvider,
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('בטל הזמנה'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                textStyle:
                    AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      );
    }

    // isAwaitingConfirmation
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sapphire.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.sapphire.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded,
              size: 16, color: AppColors.sapphire),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ממתין לאישור בעל החיה שהשירות הושלם',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
