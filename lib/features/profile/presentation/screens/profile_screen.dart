import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/section_header.dart';
import 'package:petpal/core/widgets/tiny_chip.dart';
import 'package:petpal/features/auth/domain/enums/user_role.dart';
import 'package:petpal/features/profile/domain/entities/user_profile.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    context.go('/');
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text(
            '\u05dc\u05d4\u05ea\u05e0\u05ea\u05e7 \u05de\u05d4\u05d7\u05e9\u05d1\u05d5\u05df?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
              '\u05ea\u05d5\u05db\u05dc/\u05d9 \u05dc\u05d4\u05ea\u05d7\u05d1\u05e8 \u05e9\u05d5\u05d1 \u05d1\u05db\u05dc \u05d6\u05de\u05df.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('\u05d1\u05d9\u05d8\u05d5\u05dc'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _logout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('\u05d4\u05ea\u05e0\u05ea\u05e7\u05d5\u05ea',
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
        backgroundColor: const Color(0xFF0F766E),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
          title: const Text(
            '\u05e4\u05e8\u05d5\u05e4\u05d9\u05dc',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          actions: [
            IconButton(
              tooltip: '\u05d4\u05ea\u05e0\u05ea\u05e7\u05d5\u05ea',
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      const Color(0xFFECFDF5),
                      const Color(0xFFF6F7FB),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),

            // subtle blobs
            Positioned(
              top: -130,
              left: -90,
              child: Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF34D399).withOpacity(0.20),
                      const Color(0xFF0EA5E9).withOpacity(0.12),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 90,
              right: -120,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF22C55E).withOpacity(0.12),
                      const Color(0xFF0F766E).withOpacity(0.14),
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: profileAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                    child: Text(
                        '\u05e9\u05d2\u05d9\u05d0\u05d4 \u05d1\u05d8\u05e2\u05d9\u05e0\u05ea \u05d4\u05e4\u05e8\u05d5\u05e4\u05d9\u05dc')),
                data: (profile) {
                  if (profile == null) {
                    return const Center(
                        child: Text(
                            '\u05dc\u05d0 \u05e0\u05de\u05e6\u05d0 \u05e4\u05e8\u05d5\u05e4\u05d9\u05dc'));
                  }
                  return _ProfileBody(
                    profile: profile,
                    onEdit: () => context.push('/profile/edit'),
                    onSecurity: () => context.push('/profile/security'),
                    onPrivacy: () => context.push('/profile/privacy'),
                    onShare: () =>
                        _toast(context, 'TODO: \u05e9\u05d9\u05ea\u05d5\u05e3 \u05e4\u05e8\u05d5\u05e4\u05d9\u05dc'),
                    onLogout: () => _confirmLogout(context),
                    onToast: (msg) => _toast(context, msg),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onSecurity;
  final VoidCallback onPrivacy;
  final VoidCallback onShare;
  final VoidCallback onLogout;
  final void Function(String) onToast;

  const _ProfileBody({
    required this.profile,
    required this.onEdit,
    required this.onSecurity,
    required this.onPrivacy,
    required this.onShare,
    required this.onLogout,
    required this.onToast,
  });

  String get _displayName {
    final name = profile.name.trim();
    if (name.isNotEmpty) return name;
    final email = profile.email.trim();
    if (email.contains('@')) return email.split('@').first;
    return '\u05de\u05e9\u05ea\u05de\u05e9';
  }

  String get _initial {
    final s = _displayName.trim();
    if (s.isEmpty) return 'P';
    return s.characters.first.toUpperCase();
  }

  String get _roleLabel {
    switch (profile.role) {
      case UserRole.petOwner:
        return '\u05d1\u05e2\u05dc \u05d7\u05d9\u05d9\u05ea \u05de\u05d7\u05de\u05d3';
      case UserRole.serviceProvider:
        return '\u05de\u05d8\u05e4\u05dc/\u05ea';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        _ProfileHeroCard(
          initial: _initial,
          displayName: _displayName,
          email: profile.email,
          verified: profile.isVerified,
          roleLabel: _roleLabel,
          photoUrl: profile.photoUrl,
          onEdit: onEdit,
          onShare: onShare,
        ),
        const SizedBox(height: 14),

        SectionHeader(
          title: '\u05d4\u05d7\u05e9\u05d1\u05d5\u05df \u05e9\u05dc\u05d9',
          subtitle: '\u05d4\u05d2\u05d3\u05e8\u05d5\u05ea, \u05d0\u05d1\u05d8\u05d7\u05d4 \u05d5\u05e4\u05e8\u05d8\u05d9\u05d5\u05ea',
          trailing: TinyChip(
              text: profile.isVerified
                  ? '\u05de\u05d0\u05d5\u05de\u05ea'
                  : '\u05dc\u05d0 \u05de\u05d0\u05d5\u05de\u05ea'),
        ),
        const SizedBox(height: 10),

        GlassCard(
          useBlur: true,
          child: Column(
            children: [
              _SettingTile(
                icon: Icons.edit_rounded,
                title: '\u05e4\u05e8\u05d8\u05d9\u05dd \u05d0\u05d9\u05e9\u05d9\u05d9\u05dd',
                subtitle: '\u05e9\u05dd, \u05d8\u05dc\u05e4\u05d5\u05df \u05d5\u05ea\u05de\u05d5\u05e0\u05d4',
                onTap: onEdit,
              ),
              _DividerLine(),
              _SettingTile(
                icon: Icons.security_rounded,
                title: '\u05d0\u05d1\u05d8\u05d7\u05d4',
                subtitle: '\u05e1\u05d9\u05e1\u05de\u05d4, \u05d0\u05d9\u05de\u05d5\u05ea \u05d3\u05d5\u05be\u05e9\u05dc\u05d1\u05d9',
                onTap: onSecurity,
              ),
              _DividerLine(),
              _SettingTile(
                icon: Icons.privacy_tip_rounded,
                title: '\u05e4\u05e8\u05d8\u05d9\u05d5\u05ea',
                subtitle: '\u05de\u05d9 \u05e8\u05d5\u05d0\u05d4 \u05d0\u05ea \u05d4\u05e4\u05e8\u05d5\u05e4\u05d9\u05dc \u05e9\u05dc\u05da',
                onTap: onPrivacy,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        SectionHeader(
          title: '\u05d4\u05e4\u05e2\u05d9\u05dc\u05d5\u05ea \u05e9\u05dc\u05d9',
          subtitle: '\u05d4\u05d6\u05de\u05e0\u05d5\u05ea, \u05de\u05d5\u05d3\u05e2\u05d5\u05ea \u05d5\u05e9\u05d9\u05d7\u05d5\u05ea',
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: '\u05d4\u05d6\u05de\u05e0\u05d5\u05ea',
                value: '${profile.totalBookings}',
                icon: Icons.calendar_month_rounded,
                accent: const Color(0xFF0F766E),
                onTap: () => onToast('TODO: My bookings'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: '\u05d1\u05d9\u05e7\u05d5\u05e8\u05d5\u05ea',
                value: '${profile.totalReviews}',
                icon: Icons.rate_review_rounded,
                accent: const Color(0xFF0EA5E9),
                onTap: () => onToast('TODO: My reviews'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: '\u05d3\u05d9\u05e8\u05d5\u05d2',
                value: profile.rating > 0
                    ? profile.rating.toStringAsFixed(1)
                    : '-',
                icon: Icons.star_rounded,
                accent: const Color(0xFFF59E0B),
                onTap: () => onToast('TODO: Reviews'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: '\u05ea\u05e4\u05e7\u05d9\u05d3',
                value: _roleLabel,
                icon: profile.role == UserRole.serviceProvider
                    ? Icons.pets_rounded
                    : Icons.person_rounded,
                accent: const Color(0xFFFB7185),
                onTap: () {},
              ),
            ),
          ],
        ),

        // Bio section
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          const SizedBox(height: 14),
          const SectionHeader(
            title: '\u05e7\u05e6\u05ea \u05e2\u05dc\u05d9',
            subtitle: '\u05de\u05d9\u05d3\u05e2 \u05e0\u05d5\u05e1\u05e3',
          ),
          const SizedBox(height: 10),
          GlassCard(
            useBlur: true,
            padding: const EdgeInsets.all(14),
            child: Text(
              profile.bio!,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155).withOpacity(0.85),
                height: 1.5,
              ),
            ),
          ),
        ],

        const SizedBox(height: 14),

        const SectionHeader(
          title: '\u05de\u05d9\u05d3\u05e2 \u05d8\u05db\u05e0\u05d9',
          subtitle: '\u05dc\u05e6\u05d5\u05e8\u05db\u05d9 \u05ea\u05de\u05d9\u05db\u05d4',
        ),
        const SizedBox(height: 10),

        GlassCard(
          useBlur: true,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _KeyValueRow(
                k: 'UID',
                v: profile.uid,
              ),
              const SizedBox(height: 10),
              _KeyValueRow(
                k: '\u05e1\u05d8\u05d8\u05d5\u05e1 \u05d0\u05d9\u05de\u05d9\u05d9\u05dc',
                v: profile.isVerified
                    ? '\u05de\u05d0\u05d5\u05de\u05ea'
                    : '\u05dc\u05d0 \u05de\u05d0\u05d5\u05de\u05ea',
                badgeColor: profile.isVerified
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFFB7185),
              ),
              if (profile.phone != null && profile.phone!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _KeyValueRow(
                  k: '\u05d8\u05dc\u05e4\u05d5\u05df',
                  v: profile.phone!,
                ),
              ],
              if (profile.location != null &&
                  profile.location!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _KeyValueRow(
                  k: '\u05de\u05d9\u05e7\u05d5\u05dd',
                  v: profile.location!,
                ),
              ],
              const SizedBox(height: 12),
              _PrimaryOutlineButton(
                text: '\u05e9\u05dc\u05d7/\u05d9 \u05d0\u05d9\u05de\u05d9\u05d9\u05dc \u05d0\u05d9\u05de\u05d5\u05ea',
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
                              content: const Text(
                                  '\u05e0\u05e9\u05dc\u05d7 \u05d0\u05d9\u05de\u05d9\u05d9\u05dc \u05d0\u05d9\u05de\u05d5\u05ea \u2705'),
                              backgroundColor: const Color(0xFF0F766E),
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
                              content: const Text(
                                  '\u05e9\u05d2\u05d9\u05d0\u05d4 \u05d1\u05e9\u05dc\u05d9\u05d7\u05d4. \u05e0\u05e1\u05d4/\u05d9 \u05e9\u05d5\u05d1.'),
                              backgroundColor: const Color(0xFFB91C1C),
                            ),
                          );
                        }
                      },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        _DangerButton(
          text: '\u05d4\u05ea\u05e0\u05ea\u05e7\u05d5\u05ea',
          icon: Icons.logout_rounded,
          onTap: onLogout,
        ),
      ],
    );
  }
}

// ====================== UI building blocks ======================

class _ProfileHeroCard extends StatelessWidget {
  final String initial;
  final String displayName;
  final String email;
  final bool verified;
  final String roleLabel;
  final String? photoUrl;
  final VoidCallback onEdit;
  final VoidCallback onShare;

  const _ProfileHeroCard({
    required this.initial,
    required this.displayName,
    required this.email,
    required this.verified,
    required this.roleLabel,
    this.photoUrl,
    required this.onEdit,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      useBlur: true,
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: (photoUrl != null && photoUrl!.isNotEmpty)
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
                    ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 16),
                ),
              ],
              image: (photoUrl != null && photoUrl!.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (photoUrl != null && photoUrl!.isNotEmpty)
                ? null
                : Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TinyChip(
                      text: verified
                          ? '\u05de\u05d0\u05d5\u05de\u05ea \u2705'
                          : '\u05dc\u05d0 \u05de\u05d0\u05d5\u05de\u05ea',
                      color: verified
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFFB7185),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  roleLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155).withOpacity(0.82),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniPrimaryButton(
                        text: '\u05e2\u05e8\u05d9\u05db\u05d4',
                        icon: Icons.edit_rounded,
                        onTap: onEdit,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniSecondaryButton(
                        text: '\u05e9\u05d9\u05ea\u05d5\u05e3',
                        icon: Icons.ios_share_rounded,
                        onTap: onShare,
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
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFFF1F5F9),
              ),
              child: Icon(icon, color: const Color(0xFF0F766E)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155).withOpacity(0.82),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: GlassCard(
        useBlur: true,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: accent.withOpacity(0.14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
              color: const Color(0xFF334155).withOpacity(0.9),
            ),
          ),
        ),
        if (badgeColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: badgeColor!.withOpacity(0.12),
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
              color: Color(0xFF0F172A),
            ),
          ),
      ],
    );
  }
}

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
          color: enabled ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
          border: Border.all(
            color: enabled
                ? const Color(0xFF0F766E).withOpacity(0.22)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0xFF0F766E).withOpacity(0.12)
                    : const Color(0xFF64748B).withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: enabled
                    ? const Color(0xFF0F766E)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: enabled
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
            Icon(
              Icons.chevron_left_rounded,
              color:
                  enabled ? const Color(0xFF0F766E) : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _DangerButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFFFFF1F2),
          border:
              Border.all(color: const Color(0xFFFB7185).withOpacity(0.35)),
        ),
        child: Row(
          children: const [
            _DangerIcon(),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '\u05d4\u05ea\u05e0\u05ea\u05e7\u05d5\u05ea',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF9F1239),
                ),
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: Color(0xFF9F1239)),
          ],
        ),
      ),
    );
  }
}

class _DangerIcon extends StatelessWidget {
  const _DangerIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFFB7185).withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.logout_rounded, color: Color(0xFF9F1239)),
    );
  }
}

class _MiniPrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniPrimaryButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniSecondaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniSecondaryButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFF1F5F9),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF0F766E), size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: const Color(0xFFE2E8F0).withOpacity(0.7),
    );
  }
}
