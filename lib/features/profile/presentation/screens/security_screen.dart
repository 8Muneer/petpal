import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petpal/core/constants/app_constants.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/primary_gradient_button.dart';
import 'package:petpal/core/widgets/petpal_scaffold.dart';
import 'package:petpal/features/feed/presentation/providers/feed_provider.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;
  bool _showCurrentPass = false;
  bool _showNewPass = false;
  bool _showConfirmPass = false;

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

  Future<void> _changePassword() async {
    final current = _currentPassController.text;
    final newPass = _newPassController.text;
    final confirm = _confirmPassController.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showSnack('אנא מלא/י את כל השדות', isError: true);
      return;
    }

    if (newPass.length < 6) {
      _showSnack('הסיסמה החדשה חייבת להכיל לפחות 6 תווים', isError: true);
      return;
    }

    if (newPass != confirm) {
      _showSnack('הסיסמאות אינן תואמות', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        _showSnack('משתמש לא מחובר', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // Re-authenticate with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: current,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPass);

      if (!mounted) return;
      setState(() => _isLoading = false);
      _currentPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
      _showSnack('הסיסמה שונתה בהצלחה ✅');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack(_authErrorHe(e.code), isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('שגיאה בשינוי הסיסמה', isError: true);
    }
  }

  String _authErrorHe(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'הסיסמה הנוכחית שגויה';
      case 'weak-password':
        return 'הסיסמה החדשה חלשה מדי';
      case 'requires-recent-login':
        return 'נא להתנתק ולהתחבר מחדש לפני שינוי סיסמה';
      default:
        return 'שגיאה: $code';
    }
  }

  void _confirmDeleteAccount() {
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
            'מחיקת חשבון',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF9F1239),
            ),
          ),
          content: const Text(
            'האם את/ה בטוח/ה? פעולה זו תמחק את החשבון לצמיתות ולא ניתן לשחזר אותו.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _deleteAccount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9F1239),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('מחק/י חשבון',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Delete all user's feed posts (and their comments)
      await ref.read(feedRepositoryProvider).deleteAllUserPosts(user.uid);

      // 2. Delete Firestore user document
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .delete();

      // 3. Delete the Firebase Auth account
      await user.delete();

      if (!mounted) return;
      context.go('/');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (e.code == 'requires-recent-login') {
        _showSnack('נא להתנתק ולהתחבר מחדש לפני מחיקת חשבון', isError: true);
      } else {
        _showSnack('שגיאה במחיקת חשבון', isError: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('שגיאה במחיקת חשבון', isError: true);
    }
  }

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PetPalScaffold(
        body: SafeArea(
          child: SingleChildScrollView(
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
                      'אבטחה',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Change password section
                GlassCard(
                  useBlur: false,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: const Color(0xFF0F766E).withOpacity(0.12),
                            ),
                            child: const Icon(Icons.lock_outline_rounded,
                                color: Color(0xFF0F766E)),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'שינוי סיסמה',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _PasswordField(
                        controller: _currentPassController,
                        label: 'סיסמה נוכחית',
                        hint: '••••••••',
                        showPassword: _showCurrentPass,
                        onToggle: () =>
                            setState(() => _showCurrentPass = !_showCurrentPass),
                      ),
                      const SizedBox(height: 12),
                      _PasswordField(
                        controller: _newPassController,
                        label: 'סיסמה חדשה',
                        hint: '••••••••',
                        showPassword: _showNewPass,
                        onToggle: () =>
                            setState(() => _showNewPass = !_showNewPass),
                      ),
                      const SizedBox(height: 12),
                      _PasswordField(
                        controller: _confirmPassController,
                        label: 'אימות סיסמה חדשה',
                        hint: '••••••••',
                        showPassword: _showConfirmPass,
                        onToggle: () => setState(
                            () => _showConfirmPass = !_showConfirmPass),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                PrimaryGradientButton(
                  text: _isLoading ? 'שומר...' : 'שנה סיסמה',
                  icon: _isLoading
                      ? Icons.hourglass_top_rounded
                      : Icons.check_rounded,
                  onTap: _isLoading ? null : _changePassword,
                ),

                const SizedBox(height: 28),

                // Delete account section
                GlassCard(
                  useBlur: false,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: const Color(0xFFFB7185).withOpacity(0.16),
                            ),
                            child: const Icon(Icons.delete_forever_rounded,
                                color: Color(0xFF9F1239)),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'מחיקת חשבון',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF9F1239),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'מחיקת החשבון תסיר את כל המידע שלך לצמיתות.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155).withOpacity(0.82),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _confirmDeleteAccount,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: const Color(0xFFFFF1F2),
                            border: Border.all(
                                color:
                                    const Color(0xFFFB7185).withOpacity(0.35)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_forever_rounded,
                                  color: Color(0xFF9F1239), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'מחק/י את החשבון',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF9F1239),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool showPassword;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.showPassword,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !showPassword,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF64748B),
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.65),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: const Color(0xFFE2E8F0).withOpacity(0.9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFF0F766E), width: 1.6),
        ),
      ),
    );
  }
}
