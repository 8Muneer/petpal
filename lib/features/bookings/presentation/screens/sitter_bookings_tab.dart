import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';
import '../widgets/active_sitting_card.dart';
import '../widgets/sitter_request_card.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:go_router/go_router.dart';

class SitterBookingsTab extends ConsumerStatefulWidget {
  const SitterBookingsTab({super.key});

  @override
  ConsumerState<SitterBookingsTab> createState() => _SitterBookingsTabState();
}

class _SitterBookingsTabState extends ConsumerState<SitterBookingsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ניהול שמירה',
                style: AppTextStyles.headlineLg,
              ),
              Text(
                'ניהול זמן אמת ואישור בקשות חדשות.',
                style: AppTextStyles.labelMd,
              ),
            ],
          ),
        ),

        // Segmented Control (Tabs)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: AppRadius.fullRadius,
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.fullRadius,
                boxShadow: AppShadows.subtle,
              ),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTextStyles.bodyBold.copyWith(fontSize: 13),
              tabs: const [
                Tab(text: 'בקשות'),
                Tab(text: 'פעיל'),
                Tab(text: 'היסטוריה'),
              ],
            ),
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestsList(),
              _buildActiveView(),
              _buildHistoryView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsList() {
    final requestsAsync = ref.watch(assignedSittingRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('שגיאה בטעינת בקשות: $e')),
      data: (allRequests) {
        final requests =
            allRequests.where((r) => r.status == SittingStatus.open).toList();

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('אין בקשות חדשות כרגע', style: AppTextStyles.bodyBold.copyWith(color: AppColors.textMuted)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: requests.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.fullRadius,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('בונוס מענה מהיר פעיל', style: AppTextStyles.labelSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Text('בקשות חדשות עבורך', style: AppTextStyles.bodyBold),
                ],
              );
            }

            final req = requests[index - 1];
            return SitterRequestCard(
              ownerName: req.ownerName,
              petName: req.petName,
              serviceType: req.sittingType == SittingType.atOwnerHome ? 'ביקור בית' : 'פנסיון ביתי',
              price: '₪${req.budget ?? '0'}',
              timeLeft: _calculateTimeLeft(req.createdAt),
              avatarUrl: req.ownerPhotoUrl ?? 'https://i.pravatar.cc/150',
              tags: req.rules.isEmpty ? ['ידידותי'] : req.rules,
              onAccept: () => _handleAccept(req),
              onRefuse: () => _handleRefuse(req),
              onTap: () => context.push('/sitting/request/${req.id}'),
            );
          },
        );
      },
    );
  }

  String _calculateTimeLeft(DateTime? createdAt) {
    if (createdAt == null) return '00:00';
    final expiry = createdAt.add(const Duration(hours: 24));
    final diff = expiry.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  void _handleAccept(SittingRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmDialog(
        title: 'אישור בקשה',
        message: 'האם אתה בטוח שברצונך לאשר את הבקשה של ${request.ownerName}?',
        confirmText: 'אשר בקשה',
      ),
    );

    if (confirmed == true) {
      await ref
          .read(sittingControllerProvider.notifier)
          .acceptRequest(request.id);
    }
  }

  void _handleRefuse(SittingRequest request) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _buildRefuseDialog(request),
    );

    if (reason != null && reason.isNotEmpty) {
      await ref
          .read(sittingControllerProvider.notifier)
          .refuseRequest(request.id, reason);
    }
  }

  Widget _buildConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.headlineSm),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('ביטול'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(confirmText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefuseDialog(SittingRequest request) {
    final controller = TextEditingController();
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('סירוב בקשה', style: AppTextStyles.headlineSm),
            const SizedBox(height: 8),
            Text('אנא ציין את סיבת הסירוב עבור ${request.ownerName}:',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'סיבת הסירוב...',
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdRadius,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ביטול'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(context, controller.text),
                    child: const Text('סירוב',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveView() {
    final requestsAsync = ref.watch(assignedSittingRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (allRequests) {
        final activeRequests =
            allRequests.where((r) => r.status == SittingStatus.taken).toList();

        if (activeRequests.isEmpty) {
          return const Center(
            child: Text('אין שמירה פעילה כרגע'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: activeRequests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final req = activeRequests[index];
            return ActiveSittingCard(request: req);
          },
        );
      },
    );
  }

  Widget _buildHistoryView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'ארכיון השמירות שלך',
            style: AppTextStyles.headlineSm.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            'כאן תוכל לצפות בכל העבודות שהשלמת בהצלחה.',
            style: AppTextStyles.labelMd,
          ),
        ],
      ),
    );
  }
}
