import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_button.dart';
import 'package:petpal/features/admin/presentation/widgets/admin_ui_components.dart';
import 'package:petpal/features/admin/presentation/widgets/global_alert_creator.dart';

import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 600),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 20.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    const AdminSectionHeader(title: 'Ecosystem Health'),
                    _buildBentoGrid(context),
                    const SizedBox(height: 32),
                    const AdminSectionHeader(title: 'Critical Actions'),
                    _buildQuickActions(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context) {
    return Column(
      children: [
        // Main high-impact card
        AdminMetricCard(
          title: 'Total Active Users',
          value: '2,842',
          icon: Icons.people_alt_outlined,
          color: AppColors.primary,
          onTap: () {},
        ),
        const SizedBox(height: 20),
        // Two smaller asymmetric cards
        Row(
          children: [
            Expanded(
              flex: 3,
              child: AdminMetricCard(
                title: 'Pending Verifications',
                value: '14',
                icon: Icons.assignment_ind_outlined,
                color: Colors.orangeAccent,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: AdminMetricCard(
                title: 'Live Alerts',
                value: '3',
                icon: Icons.notification_important_outlined,
                color: AppColors.danger,
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.organicRadius,
        boxShadow: AppShadows.premium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Global Emergency Broadcast',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Instantly notify all users about critical system updates or safety alerts.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Create Safety Alert',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const GlobalAlertCreator(),
              );
            },
            variant: AppButtonVariant.ghost,
            leadingIcon: Icons.campaign_outlined,
            height: 56,
          ),
        ],
      ),
    );
  }
}
