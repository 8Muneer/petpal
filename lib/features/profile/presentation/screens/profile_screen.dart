import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/app_card.dart';
import 'package:petpal/core/widgets/hero_decorations.dart';
import 'package:petpal/core/widgets/glass_pill.dart';
import 'package:petpal/core/widgets/tiny_chip.dart';
import 'package:petpal/features/auth/domain/enums/user_role.dart';
import 'package:petpal/features/profile/domain/entities/user_profile.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';
import 'package:petpal/core/services/seed_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/core/providers/firebase_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _entranceController;
  late Animation<double> _pulseAnim;
  late Animation<double> _anim0;
  late Animation<double> _anim1;
  late Animation<double> _anim2;
  late Animation<double> _anim3;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _anim0 = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _anim1 = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOut),
    );
    _anim2 = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.30, 0.80, curve: Curves.easeOut),
    );
    _anim3 = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 0.95, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _confirmAction(BuildContext context, String title, String content,
      VoidCallback onConfirm) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('אישור',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(msg),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    // Demo-data tools are developer/admin utilities — never show them to
    // regular users (a stray tap on "clear demo data" is destructive).
    final isAdmin =
        profileAsync.valueOrNull?.role == UserRole.admin;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (isAdmin)
            IconButton(
              tooltip: 'ניקוי נתוני דמו',
              onPressed: () => _confirmAction(
                context,
                'ניקוי נתונים?',
                'כל נתוני הדמו (משתמשים, חיות, הזמנות) יימחקו לצמיתות.',
                () async {
                  final seedService =
                      SeedService(firestore: FirebaseFirestore.instance);
                  await seedService.clearMockData();
                  if (!context.mounted) return;
                  _toast(context, 'נתוני דמו נמחקו בהצלחה');
                },
              ),
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
            ),
            if (isAdmin)
            IconButton(
              tooltip: 'יצירת נתוני דמו',
              onPressed: () => _confirmAction(
                context,
                'יצירת נתוני דמו?',
                'מערכת תיצור נתונים ריאליסטיים להדגמה.',
                () async {
                  final currentUserUid =
                      ref.read(authStateChangesProvider).valueOrNull?.uid;
                  final seedService =
                      SeedService(firestore: FirebaseFirestore.instance);
                  await seedService.seedData(currentUserId: currentUserUid);
                  if (!context.mounted) return;
                  _toast(context, 'נתוני דמו נוצרו בהצלחה');
                },
              ),
              icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            ),
            if (isAdmin)
            IconButton(
              tooltip: 'תיקון הזמנות ישנות',
              onPressed: () => _confirmAction(
                context,
                'תיקון הזמנות ישנות?',
                'הזמנות שאושרו ויש להן ביקורת יסומנו כ"הושלם" כדי להתאים לזרימת הסיום החדשה.',
                () async {
                  final seedService =
                      SeedService(firestore: FirebaseFirestore.instance);
                  final count =
                      await seedService.migrateAcceptedReviewedToCompleted();
                  if (!context.mounted) return;
                  _toast(context, 'עודכנו $count הזמנות');
                },
              ),
              icon: const Icon(Icons.published_with_changes_rounded,
                  color: Colors.white),
            ),
          ],
        ),
        body: profileAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2.5),
                SizedBox(height: 16),
                Text('טוען פרופיל...',
                    style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
          error: (e, _) => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 48),
                SizedBox(height: 16),
                Text('שגיאה בטעינת הפרופיל',
                    style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off_rounded,
                        color: AppColors.textMuted, size: 48),
                    SizedBox(height: 16),
                    Text('לא נמצא פרופיל',
                        style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              );
            }
            return _ProfileBody(
              profile: profile,
              onEdit: () => context.push('/profile/edit'),
              onSecurity: () => context.push('/profile/security'),
              onPrivacy: () => context.push('/profile/privacy'),
              onShare: () {
                Clipboard.setData(ClipboardData(
                    text: 'PetPal — ${profile.name}\n${profile.email}'));
                _toast(context, 'הפרופיל הועתק ללוח');
              },
              onToast: (msg) => _toast(context, msg),
              pulseAnim: _pulseAnim,
              anim0: _anim0,
              anim1: _anim1,
              anim2: _anim2,
              anim3: _anim3,
            );
          },
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Profile Body
// ═════════════════════════════════════════════════════════════════════════════

class _ProfileBody extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onSecurity;
  final VoidCallback onPrivacy;
  final VoidCallback onShare;
  final void Function(String) onToast;
  final Animation<double> pulseAnim;
  final Animation<double> anim0;
  final Animation<double> anim1;
  final Animation<double> anim2;
  final Animation<double> anim3;

  const _ProfileBody({
    required this.profile,
    required this.onEdit,
    required this.onSecurity,
    required this.onPrivacy,
    required this.onShare,
    required this.onToast,
    required this.pulseAnim,
    required this.anim0,
    required this.anim1,
    required this.anim2,
    required this.anim3,
  });

  String get _displayName {
    final name = profile.name.trim();
    if (name.isNotEmpty) return name;
    final email = profile.email.trim();
    if (email.contains('@')) return email.split('@').first;
    return 'משתמש';
  }

  String get _initial {
    final s = _displayName.trim();
    if (s.isEmpty) return 'P';
    return s.characters.first.toUpperCase();
  }

  String get _roleLabel {
    switch (profile.role) {
      case UserRole.petOwner:
        return 'בעל חיית מחמד';
      case UserRole.serviceProvider:
        return 'מטפל/ת';
      case UserRole.admin:
        return 'מנהל מערכת';
    }
  }

  Animation<Offset> _slide(Animation<double> anim) =>
      Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
          .animate(anim);

  @override
  Widget build(BuildContext context) {
    final sectionGap =
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.033);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero (full-bleed) ──────────────────────────────────────────
              FadeTransition(
                opacity: anim0,
                child: _ProfileHeroSection(
                  initial: _initial,
                  displayName: _displayName,
                  email: profile.email,
                  verified: profile.isVerified,
                  roleLabel: _roleLabel,
                  photoUrl: profile.photoUrl,
                  onEdit: onEdit,
                  onShare: onShare,
                  pulseAnim: pulseAnim,
                ),
              ),

              // ── Scrollable Content ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stats band
                    FadeTransition(
                      opacity: anim1,
                      child: SlideTransition(
                        position: _slide(anim1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SectionTitle(
                              title: 'הפעילות שלי',
                              subtitle: 'הזמנות, מודעות ושיחות',
                            ),
                            const SizedBox(height: 12),
                            _StatsBand(
                              profile: profile,
                              onBookingsTap: () =>
                                  context.push('/profile/bookings'),
                              onReviewsTap: () => onToast('TODO: My reviews'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    sectionGap,

                    // Account Settings
                    FadeTransition(
                      opacity: anim2,
                      child: SlideTransition(
                        position: _slide(anim2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SectionTitle(
                              title: 'החשבון שלי',
                              subtitle: 'הגדרות, אבטחה ופרטיות',
                              trailing: TinyChip(
                                text: profile.isVerified ? 'מאומת' : 'לא מאומת',
                                color: profile.isVerified
                                    ? AppColors.statusOpen
                                    : const Color(0xFFFB7185),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _AccountSettingsSection(
                              onEdit: onEdit,
                              onSecurity: onSecurity,
                              onPrivacy: onPrivacy,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bio (conditional)
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      sectionGap,
                      FadeTransition(
                        opacity: anim3,
                        child: SlideTransition(
                          position: _slide(anim3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _SectionTitle(title: 'קצת עלי'),
                              const SizedBox(height: 12),
                              _BioSection(bio: profile.bio!),
                            ],
                          ),
                        ),
                      ),
                    ],

                    sectionGap,

                    // Technical Info
                    FadeTransition(
                      opacity: anim3,
                      child: SlideTransition(
                        position: _slide(anim3),
                        child: _TechnicalInfoSection(profile: profile),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Hero Section
// ═════════════════════════════════════════════════════════════════════════════

class _ProfileHeroSection extends StatelessWidget {
  final String initial;
  final String displayName;
  final String email;
  final bool verified;
  final String roleLabel;
  final String? photoUrl;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final Animation<double> pulseAnim;

  const _ProfileHeroSection({
    required this.initial,
    required this.displayName,
    required this.email,
    required this.verified,
    required this.roleLabel,
    this.photoUrl,
    required this.onEdit,
    required this.onShare,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final screenH = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: max(screenH * 0.42, 380.0),
      child: Stack(
        children: [
          // Layer 1: velvet gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.velvetGradient,
              ),
            ),
          ),

          // Layer 2: dot grid texture
          const Positioned.fill(
            child: CustomPaint(painter: DotGridPainter()),
          ),

          // Layer 3: decorative circles
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 70,
            left: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
          ),

          // Layer 4: centered content
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: topPadding - 5, bottom: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated avatar ring
                  AnimatedBuilder(
                    animation: pulseAnim,
                    builder: (context, _) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Transform.scale(
                            scale: pulseAnim.value,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(
                                        alpha: 0.22 * pulseAnim.value),
                                    blurRadius: 28,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Inner white ring border
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.65),
                                width: 2.0,
                              ),
                            ),
                          ),
                          // Avatar image or fallback
                          ClipOval(
                            child: SizedBox(
                              width: 86,
                              height: 86,
                              child: (photoUrl != null && photoUrl!.isNotEmpty)
                                  ? Image.network(
                                      photoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _AvatarFallback(initial: initial),
                                    )
                                  : _AvatarFallback(initial: initial),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // Name
                  Text(
                    displayName,
                    style: GoogleFonts.frankRuhlLibre(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black.withValues(alpha: 0.30),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Role + verification badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GlassPill(
                        blur: 10,
                        opacity: 0.18,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        child: Text(
                          roleLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GlassPill(
                        blur: 10,
                        opacity: 0.18,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              verified
                                  ? Icons.verified_rounded
                                  : Icons.cancel_rounded,
                              size: 13,
                              color: verified
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFFCA5A5),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              verified ? 'מאומת' : 'לא מאומת',
                              style: TextStyle(
                                color: verified
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFFFCA5A5),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: onEdit,
                        child: const GlassPill(
                          blur: 12,
                          opacity: 0.22,
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 22, vertical: 11),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 7),
                              Text(
                                'עריכה',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onShare,
                        child: const GlassPill(
                          blur: 12,
                          opacity: 0.22,
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 22, vertical: 11),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.ios_share_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 7),
                              Text(
                                'שיתוף',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Layer 5: wave clip at the bottom
          Positioned(
            bottom: -10,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: const HeroWaveClipper(),
              child: Container(
                height: 40,
                color: AppColors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AvatarFallback extends StatelessWidget {
  final String initial;
  const _AvatarFallback({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Section Title
// ═════════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SectionTitle({required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: subtitle != null ? 30 : 20,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headlineSm),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: AppTextStyles.labelMd),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Stats Band (3-column compact row)
// ═════════════════════════════════════════════════════════════════════════════

class _StatsBand extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onBookingsTap;
  final VoidCallback onReviewsTap;

  const _StatsBand({
    required this.profile,
    required this.onBookingsTap,
    required this.onReviewsTap,
  });

  @override
  Widget build(BuildContext context) {
    final ratingValue =
        profile.rating > 0 ? profile.rating.toStringAsFixed(1) : '—';

    return AppCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _BandStat(
                label: 'הזמנות',
                value: '${profile.totalBookings}',
                accent: AppColors.primary,
                onTap: onBookingsTap,
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.divider,
            ),
            Expanded(
              child: _BandStat(
                label: 'ביקורות',
                value: '${profile.totalReviews}',
                accent: const Color(0xFF0EA5E9),
                onTap: onReviewsTap,
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.divider,
            ),
            Expanded(
              child: _BandStat(
                label: 'דירוג',
                value: ratingValue,
                accent: AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BandStat extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final VoidCallback? onTap;

  const _BandStat({
    required this.label,
    required this.value,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: GoogleFonts.frankRuhlLibre(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: accent,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: AppTextStyles.labelMd, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Account Settings Section
// ═════════════════════════════════════════════════════════════════════════════

class _AccountSettingsSection extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onSecurity;
  final VoidCallback onPrivacy;

  const _AccountSettingsSection({
    required this.onEdit,
    required this.onSecurity,
    required this.onPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _PremiumSettingTile(
            icon: Icons.edit_rounded,
            title: 'פרטים אישיים',
            subtitle: 'שם, טלפון ותמונה',
            accent: AppColors.primary,
            onTap: onEdit,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, thickness: 0.8, color: AppColors.divider),
          ),
          _PremiumSettingTile(
            icon: Icons.security_rounded,
            title: 'אבטחה',
            subtitle: 'סיסמה, אימות דו-שלבי',
            accent: AppColors.sapphire,
            onTap: onSecurity,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, thickness: 0.8, color: AppColors.divider),
          ),
          _PremiumSettingTile(
            icon: Icons.privacy_tip_rounded,
            title: 'פרטיות',
            subtitle: 'מי רואה את הפרופיל שלך',
            accent: AppColors.regalNavy,
            onTap: onPrivacy,
          ),
        ],
      ),
    );
  }
}

class _PremiumSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _PremiumSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.xlRadius,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Gradient accent bar (appears on reading-start side in RTL)
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.45)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Gradient icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.70)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.26),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppTextStyles.labelMd),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Bio Section
// ═════════════════════════════════════════════════════════════════════════════

class _BioSection extends StatelessWidget {
  final String bio;
  const _BioSection({required this.bio});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decorative opening quote (on the reading-start side in RTL = right)
          Text(
            '"',
            style: GoogleFonts.frankRuhlLibre(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: AppColors.primary.withValues(alpha: 0.15),
              height: 0.8,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              bio,
              style: AppTextStyles.bodyMd.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary.withValues(alpha: 0.85),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Technical Info Section
// ═════════════════════════════════════════════════════════════════════════════

class _TechnicalInfoSection extends StatelessWidget {
  final UserProfile profile;
  const _TechnicalInfoSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: const Icon(Icons.info_outline_rounded,
              color: AppColors.textMuted, size: 18),
          title: Text(
            'מידע טכני',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
          subtitle: Text('לצורכי תמיכה', style: AppTextStyles.labelSm),
          children: [
            _KeyValueRow(
              k: 'UID',
              v: profile.uid.length > 14
                  ? '${profile.uid.substring(0, 14)}...'
                  : profile.uid,
            ),
            const SizedBox(height: 10),
            _KeyValueRow(
              k: 'סטטוס אימייל',
              v: profile.isVerified ? 'מאומת' : 'לא מאומת',
              badgeColor: profile.isVerified
                  ? AppColors.statusOpen
                  : const Color(0xFFFB7185),
            ),
            if (profile.phone != null && profile.phone!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _KeyValueRow(k: 'טלפון', v: profile.phone!),
            ],
            if (profile.location != null && profile.location!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _KeyValueRow(k: 'מיקום', v: profile.location!),
            ],
            const SizedBox(height: 12),
            _PrimaryOutlineButton(
              text: 'שלח/י אימייל אימות',
              icon: Icons.mark_email_read_rounded,
              onTap: profile.isVerified
                  ? null
                  : () async {
                      try {
                        await FirebaseAuth.instance.currentUser
                            ?.sendEmailVerification();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            content: const Text('נשלח אימייל אימות ✅'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            content: const Text('שגיאה בשליחה. נסה/י שוב.'),
                            backgroundColor: const Color(0xFFB91C1C),
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Preserved: _KeyValueRow
// ═════════════════════════════════════════════════════════════════════════════

class _KeyValueRow extends StatelessWidget {
  final String k;
  final String v;
  final Color? badgeColor;

  const _KeyValueRow({required this.k, required this.v, this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            k,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF334155).withValues(alpha: 0.9),
            ),
          ),
        ),
        if (badgeColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: badgeColor!.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              v,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: badgeColor!,
              ),
            ),
          )
        else
          Text(
            v,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Preserved: _PrimaryOutlineButton
// ═════════════════════════════════════════════════════════════════════════════

class _PrimaryOutlineButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;

  const _PrimaryOutlineButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: enabled ? onTap : null,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: enabled ? AppColors.borderFaint : const Color(0xFFF8FAFC),
          border: Border.all(
            color: enabled
                ? AppColors.primary.withValues(alpha: 0.22)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: enabled
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.textSecondary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: enabled ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color:
                      enabled ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_left_rounded,
              color: enabled ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
