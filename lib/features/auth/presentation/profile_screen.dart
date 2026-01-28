import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  User? get _user => FirebaseAuth.instance.currentUser;

  String get _displayName {
    final u = _user;
    final dn = (u?.displayName ?? '').trim();
    if (dn.isNotEmpty) return dn;

    final email = (u?.email ?? '').trim();
    if (email.contains('@')) return email.split('@').first;

    return 'משתמש';
  }

  String get _email => (_user?.email ?? 'אין אימייל').trim();

  String get _initial {
    final s = _displayName.trim();
    if (s.isEmpty) return 'P';
    return s.characters.first.toUpperCase();
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
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
            'להתנתק מהחשבון?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text('תוכל/י להתחבר שוב בכל זמן.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ביטול'),
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
              child: const Text('התנתקות',
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
  Widget build(BuildContext context) {
    final u = _user;
    final isVerified = u?.emailVerified ?? false;
    final uid = u?.uid ?? '-';

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
            'פרופיל',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'התנתקות',
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  _ProfileHeroCard(
                    initial: _initial,
                    displayName: _displayName,
                    email: _email,
                    verified: isVerified,
                    onEdit: () => _toast(context, 'TODO: עריכת פרופיל'),
                    onShare: () => _toast(context, 'TODO: שיתוף פרופיל'),
                  ),
                  const SizedBox(height: 14),

                  _SectionHeader(
                    title: 'החשבון שלי',
                    subtitle: 'הגדרות, אבטחה ופרטיות',
                    trailing: _TinyChip(text: isVerified ? 'מאומת' : 'לא מאומת'),
                  ),
                  const SizedBox(height: 10),

                  _GlassCard(
                    child: Column(
                      children: [
                        _SettingTile(
                          icon: Icons.edit_rounded,
                          title: 'פרטים אישיים',
                          subtitle: 'שם, טלפון ותמונה',
                          onTap: () => _toast(context, 'TODO: Personal details'),
                        ),
                        _DividerLine(),
                        _SettingTile(
                          icon: Icons.security_rounded,
                          title: 'אבטחה',
                          subtitle: 'סיסמה, אימות דו־שלבי',
                          onTap: () => _toast(context, 'TODO: Security'),
                        ),
                        _DividerLine(),
                        _SettingTile(
                          icon: Icons.privacy_tip_rounded,
                          title: 'פרטיות',
                          subtitle: 'מי רואה את הפרופיל שלך',
                          onTap: () => _toast(context, 'TODO: Privacy'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  _SectionHeader(
                    title: 'הפעילות שלי',
                    subtitle: 'הזמנות, מודעות ושיחות',
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'הזמנות',
                          value: '3',
                          icon: Icons.calendar_month_rounded,
                          accent: const Color(0xFF0F766E),
                          onTap: () => _toast(context, 'TODO: My bookings'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'מודעות',
                          value: '2',
                          icon: Icons.post_add_rounded,
                          accent: const Color(0xFF0EA5E9),
                          onTap: () => _toast(context, 'TODO: My posts'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'שיחות',
                          value: '5',
                          icon: Icons.chat_bubble_rounded,
                          accent: const Color(0xFFFB7185),
                          onTap: () => _toast(context, 'TODO: My chats'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'דירוג',
                          value: '4.8',
                          icon: Icons.star_rounded,
                          accent: const Color(0xFFF59E0B),
                          onTap: () => _toast(context, 'TODO: Reviews'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _SectionHeader(
                    title: 'מידע טכני',
                    subtitle: 'לצורכי תמיכה',
                  ),
                  const SizedBox(height: 10),

                  _GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _KeyValueRow(
                          k: 'UID',
                          v: uid,
                        ),
                        const SizedBox(height: 10),
                        _KeyValueRow(
                          k: 'סטטוס אימייל',
                          v: isVerified ? 'מאומת' : 'לא מאומת',
                          badgeColor:
                              isVerified ? const Color(0xFF22C55E) : const Color(0xFFFB7185),
                        ),
                        const SizedBox(height: 12),
                        _PrimaryOutlineButton(
                          text: 'שלח/י אימייל אימות',
                          icon: Icons.mark_email_read_rounded,
                          onTap: isVerified
                              ? null
                              : () async {
                                  try {
                                    await FirebaseAuth.instance.currentUser
                                        ?.sendEmailVerification();
                                    if (!context.mounted) return;
                                    _toast(context, 'נשלח אימייל אימות ✅');
                                  } catch (_) {
                                    if (!context.mounted) return;
                                    _toast(context, 'שגיאה בשליחה. נסה/י שוב.');
                                  }
                                },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _DangerButton(
                    text: 'התנתקות',
                    icon: Icons.logout_rounded,
                    onTap: () => _confirmLogout(context),
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

// ====================== UI building blocks ======================

class _ProfileHeroCard extends StatelessWidget {
  final String initial;
  final String displayName;
  final String email;
  final bool verified;
  final VoidCallback onEdit;
  final VoidCallback onShare;

  const _ProfileHeroCard({
    required this.initial,
    required this.displayName,
    required this.email,
    required this.verified,
    required this.onEdit,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
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
            ),
            child: Center(
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
                    _TinyChip(
                      text: verified ? 'מאומת ✅' : 'לא מאומת',
                      color: verified
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFFB7185),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
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
                        text: 'עריכה',
                        icon: Icons.edit_rounded,
                        onTap: onEdit,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniSecondaryButton(
                        text: 'שיתוף',
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155).withOpacity(0.78),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
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
      child: _GlassCard(
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
                color: enabled ? const Color(0xFF0F766E) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: enabled ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                ),
              ),
            ),
            Icon(
              Icons.chevron_left_rounded,
              color: enabled ? const Color(0xFF0F766E) : const Color(0xFF64748B),
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
          border: Border.all(color: const Color(0xFFFB7185).withOpacity(0.35)),
        ),
        child: Row(
          children: const [
            _DangerIcon(),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'התנתקות',
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

class _TinyChip extends StatelessWidget {
  final String text;
  final Color? color;

  const _TinyChip({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF0F766E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: c,
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

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.76),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.48)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 26,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
