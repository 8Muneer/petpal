import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/admin/domain/entities/report_model.dart';
import 'package:petpal/features/admin/data/repositories/moderation_repository.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportContentDialog extends ConsumerStatefulWidget {
  final String targetId;
  final ReportType type;

  const ReportContentDialog({
    super.key,
    required this.targetId,
    required this.type,
  });

  @override
  ConsumerState<ReportContentDialog> createState() => _ReportContentDialogState();
}

class _ReportContentDialogState extends ConsumerState<ReportContentDialog> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _predefinedReasons = [
    'Spam',
    'Inappropriate content',
    'Harassment',
    'Hate speech',
    'False information',
    'Other',
  ];

  String? _selectedReason;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _selectedReason == 'Other' ? _reasonController.text.trim() : _selectedReason;
    
    if (reason == null || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a reason')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final report = ContentReport(
      id: '',
      targetId: widget.targetId,
      type: widget.type,
      reporterId: FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
      reason: reason,
      status: ReportStatus.open,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(moderationRepositoryProvider).submitReport(report);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you. We will review this content.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
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
            'Report Content',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Why are you reporting this ${widget.type.name}?',
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
          if (_selectedReason == 'Other') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Describe the issue...',
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
            label: 'Submit Report',
            expand: true,
            onTap: _isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
