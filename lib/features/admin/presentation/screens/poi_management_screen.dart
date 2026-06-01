import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/admin/data/repositories/admin_repository.dart';
import 'package:petpal/features/explore/domain/entities/poi_model.dart';
import 'package:petpal/features/admin/presentation/widgets/poi_editor_form.dart';
import 'package:petpal/features/admin/presentation/widgets/admin_ui_components.dart';
import 'package:petpal/core/widgets/app_button.dart';

class POIManagementScreen extends ConsumerWidget {
  const POIManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminRepo = ref.watch(adminRepositoryProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Point of Interest Directory',
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
              AppButton(
                label: 'Add Place',
                onTap: () => _showPOIEditor(context),
                variant: AppButtonVariant.secondary,
                leadingIcon: Icons.add_location_alt_outlined,
                expand: false,
                height: 40,
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<POI>>(
            stream: adminRepo.watchAllPOIs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final pois = snapshot.data ?? [];

              if (pois.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                itemCount: pois.length,
                itemBuilder: (context, index) {
                  final poi = pois[index];
                  return _buildPOICard(context, ref, poi);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined,
              size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'No places found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start by adding a dog park, vet clinic, or pet store.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPOICard(BuildContext context, WidgetRef ref, POI poi) {
    Color typeColor;
    IconData typeIcon;

    switch (poi.type) {
      case POIType.park:
        typeColor = Colors.green;
        typeIcon = Icons.park_rounded;
        break;
      case POIType.vet:
        typeColor = Colors.blue;
        typeIcon = Icons.local_hospital_rounded;
        break;
      case POIType.store:
        typeColor = Colors.orange;
        typeIcon = Icons.shopping_bag_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(typeIcon, color: typeColor),
        ),
        title: Text(
          poi.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(poi.address ?? 'No address set',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                AdminStatusBadge(
                    label: poi.type.name.toUpperCase(), color: typeColor),
                if (poi.isEmergency) ...[
                  const SizedBox(width: 8),
                  const AdminStatusBadge(label: 'EMERGENCY', color: Colors.red),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
          onSelected: (val) {
            if (val == 'edit') {
              _showPOIEditor(context, poi: poi);
            } else if (val == 'delete') {
              _confirmDelete(context, ref, poi);
            }
          },
        ),
      ),
    );
  }

  void _showPOIEditor(BuildContext context, {POI? poi}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: POIEditorForm(poi: poi),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, POI poi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Place?'),
        content: Text(
            'Are you sure you want to delete "${poi.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(adminRepositoryProvider).deletePOI(poi.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
