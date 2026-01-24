import 'package:flutter/material.dart';
import 'package:petpal/core/theme/app_theme.dart';

class GuestHomeScreen extends StatelessWidget {
  static const String _logTag = '[GuestHomeScreen]';

  const GuestHomeScreen({super.key});

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('$_logTag $message');
    if (error != null) debugPrint('$_logTag   error: $error');
    if (stackTrace != null) debugPrint('$_logTag   stackTrace: $stackTrace');
  }

  @override
  Widget build(BuildContext context) {
    _log('build');
    try {
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
              // Lost & Found Alerts Section
              SliverToBoxAdapter(
                child: _buildSectionTitle('התראות אבודים ומצויים'),
              ),
              SliverToBoxAdapter(
                child: _buildLostAndFoundList(),
              ),
              // Bottom Padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          ),
        ),
      );
    } catch (e, st) {
      _log('build failed', error: e, stackTrace: st);
      return Scaffold(
        backgroundColor: AppColors.surfaceAlabaster,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.alertCoral),
                  const SizedBox(height: 12),
                  const Text(
                    'משהו השתבש במסך הבית',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondarySlate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.secondarySlate),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'שלום 👋',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondarySlate,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'מצא מטפל מושלם לחיית המחמד שלך',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.secondarySlate.withOpacity(0.65),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.secondarySlate,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              icon: Icons.search,
              title: 'חיפוש מטפל',
              subtitle: 'מצא מטפל לפי מיקום ותאריך',
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.add_circle_outline,
              title: 'פרסם מודעה',
              subtitle: 'אבוד/נמצא או שירות חדש',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.secondarySlate,
        ),
      ),
    );
  }

  Widget _buildSittersList() {
    return SizedBox(
      height: 170,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        children: const [
          _SitterCard(
            name: 'איה לוי',
            rating: 4.9,
            price: '₪90/יום',
            distance: '0.8 ק"מ',
          ),
          SizedBox(width: 12),
          _SitterCard(
            name: 'דניאל כהן',
            rating: 4.7,
            price: '₪70/יום',
            distance: '1.4 ק"מ',
          ),
          SizedBox(width: 12),
          _SitterCard(
            name: 'נועה מזרחי',
            rating: 4.8,
            price: '₪85/יום',
            distance: '2.0 ק"מ',
          ),
        ],
      ),
    );
  }

  Widget _buildLostAndFoundList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: const [
          _LostFoundCard(
            title: 'כלב אבוד - רקס',
            subtitle: 'נראה לאחרונה בשכונת בית הכרם',
            timeAgo: 'לפני 2 שעות',
          ),
          SizedBox(height: 12),
          _LostFoundCard(
            title: 'חתולה נמצאה - לולה',
            subtitle: 'נמצאה ליד גן סאקר',
            timeAgo: 'אתמול',
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySage.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primarySage),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.secondarySlate,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondarySlate.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _SitterCard extends StatelessWidget {
  final String name;
  final double rating;
  final String price;
  final String distance;

  const _SitterCard({
    required this.name,
    required this.rating,
    required this.price,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.warmMist,
                child: Text(
                  name.characters.first,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondarySlate,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondarySlate,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primarySage,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'מרחק: $distance',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondarySlate.withOpacity(0.65),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // placeholder (no navigation here yet)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySage,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('בקשת הזמנה'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LostFoundCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timeAgo;

  const _LostFoundCard({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warmMist,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.campaign_outlined, color: AppColors.secondarySlate),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondarySlate,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondarySlate.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            timeAgo,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.secondarySlate.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}
