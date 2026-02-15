import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/petpal_scaffold.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool? _showPhone;
  bool? _showEmail;
  bool? _showLocation;
  bool _isLoading = false;
  bool _initialized = false;

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFB91C1C) : const Color(0xFF0F766E),
      ),
    );
  }

  Future<void> _save(String uid) async {
    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'showPhone': _showPhone ?? true,
      'showEmail': _showEmail ?? true,
      'showLocation': _showLocation ?? true,
    };

    final repo = ref.read(profileRepositoryProvider);
    final result = await repo.updateProfile(uid, data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) =>
          _showSnack('שגיאה בשמירה: ${failure.message}', isError: true),
      (_) {
        _showSnack('הגדרות הפרטיות עודכנו ✅');
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PetPalScaffold(
        body: SafeArea(
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                const Center(child: Text('שגיאה בטעינת הפרופיל')),
            data: (profile) {
              if (profile == null) {
                return const Center(child: Text('לא נמצא פרופיל'));
              }

              if (!_initialized) {
                _initialized = true;
                _showPhone = profile.showPhone;
                _showEmail = profile.showEmail;
                _showLocation = profile.showLocation;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'פרטיות',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Info card
                    GlassCard(
                      useBlur: false,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: const Color(0xFF0F766E).withOpacity(0.12),
                            ),
                            child: const Icon(Icons.privacy_tip_rounded,
                                color: Color(0xFF0F766E)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'בחר/י אילו פרטים יהיו גלויים למשתמשים אחרים בפרופיל שלך.',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color:
                                    const Color(0xFF334155).withOpacity(0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Privacy toggles
                    GlassCard(
                      useBlur: false,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          _PrivacyToggle(
                            icon: Icons.phone_rounded,
                            title: 'הצג טלפון',
                            subtitle: 'אפשר למשתמשים אחרים לראות את מספר הטלפון שלך',
                            value: _showPhone ?? true,
                            onChanged: (v) =>
                                setState(() => _showPhone = v),
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: const Color(0xFFE2E8F0).withOpacity(0.7),
                          ),
                          _PrivacyToggle(
                            icon: Icons.email_rounded,
                            title: 'הצג אימייל',
                            subtitle: 'אפשר למשתמשים אחרים לראות את כתובת האימייל שלך',
                            value: _showEmail ?? true,
                            onChanged: (v) =>
                                setState(() => _showEmail = v),
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: const Color(0xFFE2E8F0).withOpacity(0.7),
                          ),
                          _PrivacyToggle(
                            icon: Icons.location_on_rounded,
                            title: 'הצג מיקום',
                            subtitle: 'אפשר למשתמשים אחרים לראות את המיקום שלך',
                            value: _showLocation ?? true,
                            onChanged: (v) =>
                                setState(() => _showLocation = v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save button
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _isLoading ? null : () => _save(profile.uid),
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [Color(0xFF0F766E), Color(0xFF22C55E)],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isLoading
                                  ? Icons.hourglass_top_rounded
                                  : Icons.check_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isLoading ? 'שומר...' : 'שמור שינויים',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PrivacyToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrivacyToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF0F766E),
          ),
        ],
      ),
    );
  }
}
