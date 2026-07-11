import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/admin/data/repositories/admin_repository.dart';
import 'package:petpal/features/admin/domain/entities/verification_request.dart';
import 'package:petpal/features/admin/presentation/widgets/admin_ui_components.dart';
import 'package:petpal/features/admin/presentation/widgets/verification_detail_dialog.dart';

class SitterVerificationScreen extends ConsumerWidget {
  const SitterVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminRepo = ref.watch(adminRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Provider Verification'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: StreamBuilder<List<VerificationRequest>>(
        stream: adminRepo.watchPendingVerifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildRequestCard(context, request);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No pending provider verification requests.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, VerificationRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          'User ID: ${request.userId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Requested: ${request.requestedAt.toString().split('.')[0]}'),
            const SizedBox(height: 8),
            const AdminStatusBadge(label: 'PENDING', color: Colors.orange),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => VerificationDetailDialog(request: request),
          );
        },
      ),
    );
  }
}
