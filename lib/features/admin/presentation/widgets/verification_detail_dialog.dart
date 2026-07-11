import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/admin/data/repositories/admin_repository.dart';
import 'package:petpal/features/admin/domain/entities/verification_request.dart';

class VerificationDetailDialog extends ConsumerWidget {
  final VerificationRequest request;

  const VerificationDetailDialog({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Provider Verification',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Reviewing application for User ID: ${request.userId}'),
            const SizedBox(height: 24),
            const Text(
              'Submitted Documents',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (request.documents.isEmpty)
              const Text('No documents uploaded.')
            else
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: request.documents.length,
                  itemBuilder: (context, index) {
                    final url = request.documents[index];
                    return GestureDetector(
                      onTap: () => _showFullScreenImage(context, url),
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, color: Colors.grey),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Admin Notes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Add internal notes here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleAction(context, ref, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(context, ref, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String status) async {
    final adminRepo = ref.read(adminRepositoryProvider);
    final adminId = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      await adminRepo.updateVerificationStatus(
        requestId: request.id,
        userId: request.userId,
        status: status,
        adminId: adminId,
      );
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }
}
