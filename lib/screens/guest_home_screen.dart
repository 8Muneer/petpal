import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlabaster,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar Section
            SliverToBoxAdapter(
              child: _buildHeader(context),
            ),
            // Quick Actions Section
            SliverToBoxAdapter(
              child: _buildQuickActions(),
            ),
            // Featured Sitters Section
            SliverToBoxAdapter(
              child: _buildSectionTitle('מטפלים מומלצים בסביבתך'),
            ),
            SliverToBoxAdapter(
              child: _buildSittersList(),
            ),
            // Lost & Found Alert
            SliverToBoxAdapter(
              child: _buildLostFoundAlert(),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      // Bottom Navigation
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '!בוקר טוב, אורח',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondarySlate,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'מצא את המטפל המושלם לחיית המחמד שלך',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondarySlate.withOpacity(0.7),
                ),
              ),
            ],
          ),
          // Profile Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.warmMist,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.person_outline,
              color: AppColors.primarySage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'פעולות מהירות',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.secondarySlate,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionChip('🐕 טיול', AppColors.primarySage),
              const SizedBox(width: 8),
              _buildActionChip('✂️ טיפוח', AppColors.sageSerenity),
              const SizedBox(width: 8),
              _buildActionChip('🏠 פנסיון', AppColors.sunsetAmber),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.secondarySlate,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'צפה בהכל',
              style: TextStyle(
                color: AppColors.primarySage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSittersList() {
    return SizedBox(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildSitterCard(
            name: 'דניאל כהן',
            rating: 4.9,
            reviews: 120,
            price: 50,
            distance: 1.2,
            isVerified: true,
          ),
          _buildSitterCard(
            name: 'מיכל לוי',
            rating: 4.8,
            reviews: 85,
            price: 45,
            distance: 0.8,
            isVerified: true,
          ),
          _buildSitterCard(
            name: 'יוסי אברהם',
            rating: 4.7,
            reviews: 62,
            price: 40,
            distance: 2.1,
            isVerified: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSitterCard({
    required String name,
    required double rating,
    required int reviews,
    required int price,
    required double distance,
    required bool isVerified,
  }) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.warmMist,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.cardRadius),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: AppColors.primarySage.withOpacity(0.5),
                  ),
                ),
                if (isVerified)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySage,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.verified, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'מאומת',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondarySlate,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: AppColors.sunsetAmber),
                    const SizedBox(width: 4),
                    Text(
                      '$rating ($reviews)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondarySlate.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₪$price/שעה',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primarySage,
                      ),
                    ),
                    Text(
                      '${distance}ק"מ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondarySlate.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLostFoundAlert() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.alertCoral.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.alertCoral.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.alertCoral.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: AppColors.alertCoral,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'אבד בסביבה: לונה',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.alertCoral,
                  ),
                ),
                Text(
                  'נראתה לאחרונה לפני שעתיים (2 ק"מ)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondarySlate.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.alertCoral,
              side: BorderSide(color: AppColors.alertCoral),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('עזור'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'בית', true),
              _buildNavItem(Icons.search, 'חיפוש', false),
              _buildNavItem(Icons.pets, 'טיפול', false),
              _buildNavItem(Icons.campaign, 'אבדות', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive
              ? AppColors.primarySage
              : AppColors.secondarySlate.withOpacity(0.5),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive
                ? AppColors.primarySage
                : AppColors.secondarySlate.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
