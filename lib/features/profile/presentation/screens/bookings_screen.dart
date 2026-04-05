import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/app_scaffold.dart';
import 'package:petpal/core/widgets/empty_state_card.dart';
import 'package:petpal/core/widgets/tiny_chip.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';
import 'package:petpal/features/walks/domain/entities/walk_request.dart';
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('ההזמנות שלי', style: AppTextStyles.h2),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    controller: _tabs,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: AppTextStyles.label,
                    tabs: const [
                      Tab(text: 'טיולים'),
                      Tab(text: 'שמירה'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: const [
                    _WalkBookingsTab(),
                    _SittingBookingsTab(),
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

class _WalkBookingsTab extends ConsumerWidget {
  const _WalkBookingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(walkRequestsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (requests) {
        if (requests.isEmpty) {
          return const EmptyStateWidget(
            title: 'אין בקשות טיול עדיין',
            subtitle: 'צור/י בקשת טיול חדשה מהמסך הראשי.',
            icon: Icons.directions_walk_rounded,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          itemCount: requests.length,
          itemBuilder: (ctx, i) => _WalkTile(
            request: requests[i],
            onTap: () => ctx.push('/walks/detail', extra: requests[i]),
          ),
        );
      },
    );
  }
}

class _SittingBookingsTab extends ConsumerWidget {
  const _SittingBookingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sittingRequestsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (requests) {
        if (requests.isEmpty) {
          return const EmptyStateWidget(
            title: 'אין בקשות שמירה עדיין',
            subtitle: 'צור/י בקשת שמירה חדשה מהמסך הראשי.',
            icon: Icons.house_rounded,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          itemCount: requests.length,
          itemBuilder: (ctx, i) => _SittingTile(
            request: requests[i],
            onTap: () => ctx.push('/sitting/detail', extra: requests[i]),
          ),
        );
      },
    );
  }
}

class _WalkTile extends StatelessWidget {
  final WalkRequest request;
  final VoidCallback onTap;

  const _WalkTile({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    switch (request.status) {
      case WalkStatus.open:
        statusColor = AppColors.statusOpen;
        statusLabel = 'פתוח';
        break;
      case WalkStatus.taken:
        statusColor = AppColors.warning;
        statusLabel = 'נלקח';
        break;
      case WalkStatus.closed:
        statusColor = AppColors.statusClosed;
        statusLabel = 'סגור';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.walksLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.directions_walk_rounded,
                  color: AppColors.walks),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.petName, style: AppTextStyles.bodyBold),
                  const SizedBox(height: 2),
                  Text(
                    '${request.area} • ${request.preferredTime}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            TinyChip(text: statusLabel, color: statusColor),
          ],
        ),
      ),
    );
  }
}

class _SittingTile extends StatelessWidget {
  final SittingRequest request;
  final VoidCallback onTap;

  const _SittingTile({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    switch (request.status) {
      case SittingStatus.open:
        statusColor = AppColors.statusOpen;
        statusLabel = 'פתוח';
        break;
      case SittingStatus.taken:
        statusColor = AppColors.warning;
        statusLabel = 'נלקח';
        break;
      case SittingStatus.closed:
        statusColor = AppColors.statusClosed;
        statusLabel = 'סגור';
        break;
    }

    final nights = request.numberOfNights;
    final durationText = nights > 0 ? '$nights לילות' : 'יום אחד';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.sittingLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child:
                  const Icon(Icons.house_rounded, color: AppColors.sitting),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.petName, style: AppTextStyles.bodyBold),
                  const SizedBox(height: 2),
                  Text(
                    '${request.area} • $durationText',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            TinyChip(text: statusLabel, color: statusColor),
          ],
        ),
      ),
    );
  }
}
