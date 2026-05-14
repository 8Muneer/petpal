import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/features/admin/presentation/widgets/admin_ui_components.dart';

import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 600),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 20.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    _buildOverviewHeader(context),
                    const SizedBox(height: 32),
                    const AdminSectionHeader(title: 'Growth Trends'),
                    _buildMockChart(context, 'Monthly User Growth', [0.4, 0.6, 0.5, 0.8, 0.7, 0.9]),
                    const SizedBox(height: 24),
                    _buildMockChart(context, 'Service Provider Activity', [0.3, 0.4, 0.7, 0.6, 0.8, 0.75]),
                    const SizedBox(height: 32),
                    const AdminSectionHeader(title: 'Community Pulse'),
                    _buildPulseMetrics(context),
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

  Widget _buildOverviewHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStat(
            context,
            'Avg. Booking',
            '\$42.5',
            Icons.monetization_on_outlined,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMiniStat(
            context,
            'Response Time',
            '12m',
            Icons.speed_outlined,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockChart(BuildContext context, String title, List<double> values) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: values.map((v) {
                return Container(
                  width: 30,
                  height: 100 * v,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(v > 0.7 ? 1.0 : 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('JAN', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              Text('JUN', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPulseMetrics(BuildContext context) {
    return Column(
      children: [
        _buildPulseItem('User Satisfaction', 0.92, Colors.blue),
        const SizedBox(height: 16),
        _buildPulseItem('Safety Report Clarity', 0.85, Colors.orange),
        const SizedBox(height: 16),
        _buildPulseItem('AI Matching Success', 0.78, AppColors.primary),
      ],
    );
  }

  Widget _buildPulseItem(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
