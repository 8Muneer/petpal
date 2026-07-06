import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/utils/price_formatter.dart';
import 'package:petpal/core/widgets/app_avatar.dart';
import 'package:petpal/core/widgets/app_header_bar.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/gradient_action_card.dart';

import 'package:petpal/features/walks/domain/entities/walk_service.dart';
import 'package:petpal/features/walks/presentation/providers/walk_provider.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';
import 'package:petpal/features/sitting/presentation/providers/sitting_provider.dart';

class ProviderServicesTab extends ConsumerStatefulWidget {
  /// When [standalone] is true the widget renders as a pushed page: a simple
  /// back-button header instead of the tab-style [AppHeaderBar] (which has no
  /// back affordance — it's built for the home shell's tabs).
  final bool standalone;

  const ProviderServicesTab({super.key, this.standalone = false});

  @override
  ConsumerState<ProviderServicesTab> createState() =>
      _ProviderMyServicesTabState();
}

class _ProviderMyServicesTabState extends ConsumerState<ProviderServicesTab> {
  int _selected = 0; // 0 = walk, 1 = sitting

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.standalone)
          const _StandaloneHeader(title: 'השירותים שלי')
        else
          const AppHeaderBar(title: 'השירותים שלי'),
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: GlassCard(
                  useBlur: true,
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ProviderToggleChip(
                          label: 'פרסם שירותי טיולים',
                          icon: Icons.directions_walk_rounded,
                          selected: _selected == 0,
                          onTap: () => setState(() => _selected = 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ProviderToggleChip(
                          label: 'פרסם שירותי שמירה',
                          icon: Icons.home_work_rounded,
                          selected: _selected == 1,
                          onTap: () => setState(() => _selected = 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _selected == 0
                      ? const _ProviderAdvertiseView(key: ValueKey('adv_walk'))
                      : const _ProviderSittingAdvertiseView(
                          key: ValueKey('adv_sitting')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProviderAdvertiseView extends ConsumerWidget {
  const _ProviderAdvertiseView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myServicesAsync = ref.watch(myWalkServicesProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      children: [
        // CTA card
        GlassCard(
          useBlur: true,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                    ),
                    child: const Icon(Icons.campaign_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('פרסם את שירות הטיולים שלך',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary)),
                        SizedBox(height: 2),
                        Text('הגע/י לבעלי חיות מחמד באזורך',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Benefit bullets
              const _BenefitRow(
                  icon: Icons.location_on_rounded,
                  text: 'הגע/י לבעלי חיות מחמד באזורך'),
              const SizedBox(height: 6),
              const _BenefitRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  text: 'קבל/י פניות ישירות'),
              const SizedBox(height: 6),
              const _BenefitRow(
                  icon: Icons.star_rounded,
                  text: 'בנה/י את הפרופיל המקצועי שלך'),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.push('/walks/service/create'),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                  ),
                  child: const Center(
                    child: Text('פרסם שירות חדש',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // My active services
        myServicesAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => const SizedBox.shrink(),
          data: (services) {
            if (services.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('השירותים שלי',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                ...services.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MyServiceCard(service: s, ref: ref),
                    )),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProviderSittingAdvertiseView extends ConsumerWidget {
  const _ProviderSittingAdvertiseView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myServicesAsync = ref.watch(mySittingServicesProvider);
    const purple = AppColors.sitting;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      children: [
        GlassCard(
          useBlur: true,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent]),
                    ),
                    child: const Icon(Icons.campaign_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('פרסם את שירות השמירה שלך',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary)),
                        SizedBox(height: 2),
                        Text('הגע/י לבעלי חיות מחמד באזורך',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _BenefitRow(
                  icon: Icons.location_on_rounded,
                  text: 'הגע/י לבעלי חיות מחמד באזורך'),
              const SizedBox(height: 6),
              const _BenefitRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  text: 'קבל/י פניות ישירות'),
              const SizedBox(height: 6),
              const _BenefitRow(
                  icon: Icons.star_rounded,
                  text: 'בנה/י את הפרופיל המקצועי שלך'),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.push('/sitting/service/create'),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                  ),
                  child: const Center(
                    child: Text('פרסם שירות חדש',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        myServicesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: purple)),
          error: (e, _) => const SizedBox.shrink(),
          data: (services) {
            if (services.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('השירותים שלי',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                ...services.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MySittingServiceCard(service: s, ref: ref),
                    )),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MyServiceCard extends StatelessWidget {
  final WalkService service;
  final WidgetRef ref;
  const _MyServiceCard({required this.service, required this.ref});

  @override
  Widget build(BuildContext context) {
    const teal = AppColors.primary;
    final isActive = service.isActive;

    return GlassCard(
      useBlur: true,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────
          Row(
            children: [
              LiveUserAvatar(
                uid: service.providerUid,
                fallbackName: service.providerName,
                fallbackPhotoUrl: service.providerPhotoUrl,
                size: 48,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.providerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            fontSize: 15)),
                    Text(service.area,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      formatPrice(service.priceText, service.priceType),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.duration,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isActive
                      ? AppColors.statusOpen.withValues(alpha: 0.12)
                      : AppColors.warning.withValues(alpha: 0.12),
                ),
                child: Text(
                  isActive ? 'פעיל' : 'מושהה',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isActive ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),

          // ── Pet type chips ───────────────────────────────────────────
          if (service.petTypes.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 6,
              children: service.petTypes.map((type) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: teal.withValues(alpha: 0.08),
                  ),
                  child: Text(type,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: teal)),
                );
              }).toList(),
            ),
          ],

          // ── Stats row ────────────────────────────────────────────────
          if (service.viewCount != null || service.requestCount != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (service.viewCount != null) ...[
                    const Icon(Icons.visibility_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${service.viewCount} צפיות',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                  ],
                  if (service.viewCount != null && service.requestCount != null)
                    const SizedBox(width: 12),
                  if (service.requestCount != null) ...[
                    const Icon(Icons.inbox_outlined,
                        size: 13, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('${service.requestCount} פניות',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ],
                ],
              ),
            ),
          ],

          // ── Action buttons ───────────────────────────────────────────
          const SizedBox(height: 10),
          Row(
            children: [
              // Toggle active/paused
              _ServiceActionButton(
                label: isActive ? 'השהה' : 'הפעל',
                icon: isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isActive ? AppColors.warning : teal,
                bgColor: isActive
                    ? AppColors.warning.withValues(alpha: 0.1)
                    : teal.withValues(alpha: 0.1),
                borderColor: isActive
                    ? AppColors.warning.withValues(alpha: 0.35)
                    : teal.withValues(alpha: 0.3),
                onTap: () => ref
                    .read(walkDatasourceProvider)
                    .updateWalkService(service.id, {'isActive': !isActive}),
              ),
              const SizedBox(width: 8),
              // Edit button
              _ServiceActionButton(
                label: 'ערוך',
                icon: Icons.edit_rounded,
                color: AppColors.smartBlue,
                bgColor: AppColors.smartBlue.withValues(alpha: 0.08),
                borderColor: AppColors.smartBlue.withValues(alpha: 0.3),
                onTap: () =>
                    context.push('/walks/service/create', extra: service),
              ),
              const Spacer(),
              // Delete
              GestureDetector(
                onTap: () => ref
                    .read(walkDatasourceProvider)
                    .deleteWalkService(service.id),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MySittingServiceCard extends StatelessWidget {
  final SittingService service;
  final WidgetRef ref;
  const _MySittingServiceCard({required this.service, required this.ref});

  @override
  Widget build(BuildContext context) {
    const purple = AppColors.sitting;
    final isActive = service.isActive;

    return GlassCard(
      useBlur: true,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LiveUserAvatar(
                uid: service.providerUid,
                fallbackName: service.providerName,
                fallbackPhotoUrl: service.providerPhotoUrl,
                size: 48,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.providerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            fontSize: 15)),
                    Text(service.area,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      formatPrice(service.priceText, service.priceType),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: purple),
                    ),
                    const SizedBox(height: 2),
                    Text(service.sittingLocation,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isActive
                      ? AppColors.statusOpen.withValues(alpha: 0.12)
                      : AppColors.warning.withValues(alpha: 0.12),
                ),
                child: Text(
                  isActive ? 'פעיל' : 'מושהה',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isActive ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          if (service.petTypes.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 6,
              children: service.petTypes.map((type) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: purple.withValues(alpha: 0.08),
                  ),
                  child: Text(type,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: purple)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () =>
                    context.push('/sitting/service/create', extra: service),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: purple.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 14, color: purple),
                      SizedBox(width: 4),
                      Text('עריכה',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: purple)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final ds = ref.read(sittingDatasourceProvider);
                  await ds.updateSittingService(
                      service.id, {'isActive': !service.isActive});
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isActive
                        ? AppColors.warning.withValues(alpha: 0.12)
                        : purple.withValues(alpha: 0.12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 14,
                        color: isActive ? AppColors.warning : purple,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'השהה' : 'הפעל',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isActive ? AppColors.warning : purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  final ds = ref.read(sittingDatasourceProvider);
                  await ds.deleteSittingService(service.id);
                },
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;
  const _ServiceActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: bgColor,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ProviderToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ProviderToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? AppColors.primary : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class ListYourServiceCTA extends ConsumerWidget {
  const ListYourServiceCTA({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myServicesAsync = ref.watch(mySittingServicesProvider);

    return myServicesAsync.when(
      data: (services) {
        if (services.isNotEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GradientActionCard(
            title: 'התחל להרוויח משמירה',
            subtitle:
                'פרסם את שירותי השמירה שלך והתחל לקבל פניות מבעלי חיות באזורך',
            icon: Icons.add_business_rounded,
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => context.push('/sitting/create-service'),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Standalone (pushed-page) header ─────────────────────────────────────────

/// Pushed-page variant of the tab header: same surface, divider, and title
/// typography as [AppHeaderBar], but with a back button instead of the
/// profile-menu avatar and bells (those belong to the home shell's tabs).
class _StandaloneHeader extends StatelessWidget {
  final String title;
  const _StandaloneHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: topInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SizedBox(
        height: AppHeaderBar.contentHeight,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.marginPage),
          child: Row(
            children: [
              // Leading (right in RTL): back. BackButton mirrors automatically.
              SizedBox(
                width: 48,
                child: BackButton(
                  color: AppColors.textPrimary,
                  onPressed: () => context.pop(),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineLg.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.primary,
                  ),
                ),
              ),
              // Trailing spacer keeps the title optically centered.
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}

