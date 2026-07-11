import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/admin/domain/entities/report_model.dart';
import 'package:petpal/features/admin/data/repositories/moderation_repository.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Opens [ReportContentDialog] as a bottom sheet — the single call site every
/// "report" button in the app should use, so the sheet styling and RTL
/// wrapping stay consistent wherever reporting is offered.
Future<void> showReportDialog(
  BuildContext context, {
  required String targetId,
  required ReportType type,
  String? parentId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: ReportContentDialog(
        targetId: targetId,
        type: type,
        parentId: parentId,
      ),
    ),
  );
}

class ReportContentDialog extends ConsumerStatefulWidget {
  final String targetId;
  final ReportType type;
  final String? parentId;

  const ReportContentDialog({
    super.key,
    required this.targetId,
    required this.type,
    this.parentId,
  });

  @override
  ConsumerState<ReportContentDialog> createState() => _ReportContentDialogState();
}

class _ReportContentDialogState extends ConsumerState<ReportContentDialog> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  static const _predefinedReasons = [
    'ספאם',
    'תוכן לא הולם',
    'הטרדה',
    'דברי שטנה',
    'מידע שגוי',
    'אחר',
  ];

  String? _selectedReason;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _typeLabel(ReportType type) => switch (type) {
        ReportType.post => 'פוסט',
        ReportType.comment => 'תגובה',
        ReportType.user => 'משתמש',
        ReportType.message => 'הודעה',
      };

  Future<void> _submit() async {
    final reason =
        _selectedReason == 'אחר' ? _reasonController.text.trim() : _selectedReason;

    if (reason == null || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('יש לבחור או להזין סיבה')),
      );
      return;
    }

    final reporterId = FirebaseAuth.instance.currentUser?.uid;
    if (reporterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('יש להתחבר כדי לדווח')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final report = ContentReport(
      id: '',
      targetId: widget.targetId,
      type: widget.type,
      reporterId: reporterId,
      reason: reason,
      status: ReportStatus.open,
      createdAt: DateTime.now(),
      parentId: widget.parentId,
    );

    try {
      await ref.read(moderationRepositoryProvider).submitReport(report);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('תודה, נבדוק את התוכן בהקדם.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בשליחת הדיווח: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        right: 24,
        left: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'דיווח על תוכן',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'מה הסיבה לדיווח על ה${_typeLabel(widget.type)} הזה?',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _predefinedReasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return ChoiceChip(
                label: Text(reason),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedReason = selected ? reason : null);
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
          if (_selectedReason == 'אחר') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'פרט/י את הבעיה...',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              maxLines: 3,
            ),
          ],
          const SizedBox(height: 32),
          AppButton(
            label: 'שלח דיווח',
            expand: true,
            isLoading: _isSubmitting,
            onTap: _isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
