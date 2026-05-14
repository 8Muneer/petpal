import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/community/presentation/providers/create_post_provider.dart';
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';

class ServiceLookupField extends ConsumerWidget {
  const ServiceLookupField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedServiceName = ref.watch(createPostProvider.select((s) => s.linkedServiceName));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'תיוג שירות (אופציונלי)',
          style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (linkedServiceName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    linkedServiceName,
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () => ref.read(createPostProvider.notifier).clearLinkedService(),
                  child: const Icon(Icons.close, color: AppColors.primary, size: 20),
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: () => _showServicePicker(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.textMuted),
                  const SizedBox(width: 12),
                  Text(
                    'חפש שירות לתיוג...',
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showServicePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('בחר שירות לתיוג', style: AppTextStyles.h3),
            const SizedBox(height: 20),
            Expanded(
              child: ref.watch(sittingServicesProvider).when(
                data: (services) => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return _ServiceTile(
                      name: service.providerName,
                      type: service.sittingLocation,
                      onTap: () {
                        ref.read(createPostProvider.notifier).setLinkedService(service.id, service.providerName);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading services: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final String name;
  final String type;
  final VoidCallback onTap;

  const _ServiceTile({required this.name, required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.storefront, color: AppColors.primary),
      ),
      title: Text(name, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Text(type, style: AppTextStyles.labelSm),
      trailing: const Icon(Icons.chevron_right, color: AppColors.border),
    );
  }
}
