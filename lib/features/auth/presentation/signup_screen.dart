import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:petpal/core/theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

  // ✅ default: Pet Owner selected (like your screenshot)
  bool _isPetOwnerSelected = true;

  // Firestore (users collection)
  final _usersRef = FirebaseFirestore.instance.collection('users');

  static const String _logTag = '[SignupScreen]';

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('$_logTag $message');
    if (error != null) debugPrint('$_logTag   error: $error');
    if (stackTrace != null) debugPrint('$_logTag   stackTrace: $stackTrace');
  }

  @override
  void dispose() {
    _log('dispose');
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    _log(
      'attempting signup',
      error:
          'email=$email, nameLength=${name.length}, passwordLength=${password.length}, role=${_isPetOwnerSelected ? 'owner' : 'provider'}',
    );

    if (!_acceptTerms) {
      _showSnack('יש לאשר את תנאי השימוש', isError: true);
      return;
    }
    if (name.isEmpty) {
      _showSnack('אנא הזן/י שם מלא', isError: true);
      return;
    }
    if (email.isEmpty) {
      _showSnack('אנא הזן/י כתובת אימייל', isError: true);
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      _showSnack('כתובת אימייל לא תקינה', isError: true);
      return;
    }

    if (password.isEmpty) {
      _showSnack('אנא הזן/י סיסמה', isError: true);
      return;
    }
    if (password.length < 6) {
      _showSnack('הסיסמה חייבת להכיל לפחות 6 תווים', isError: true);
      return;
    }
    if (password != confirmPassword) {
      _showSnack('הסיסמאות אינן תואמות', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;

      // display name (non-fatal)
      try {
        await credential.user?.updateDisplayName(name);
      } catch (_) {}

      // ✅ Save role in Firestore (non-fatal)
      if (uid != null) {
        try {
          await _usersRef.doc(uid).set(
            {
              'uid': uid,
              'name': name,
              'email': email,
              'role': _isPetOwnerSelected ? 'owner' : 'provider',
              'isVerified': false,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          _log('Firestore user doc upserted');
        } catch (e, st) {
          _log('Firestore user doc write failed (non-fatal)',
              error: e, stackTrace: st);
        }
      }

      if (!mounted) return;

      _showSnack('החשבון נוצר בהצלחה ✅');

      // ✅ go to home after signup
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showSnack(_friendlyRegisterErrorHe(e), isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('שגיאה לא צפויה. נסה/י שוב.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.alertCoral : AppColors.primarySage,
      ),
    );
  }

  String _friendlyRegisterErrorHe(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'האימייל כבר בשימוש';
      case 'invalid-email':
        return 'כתובת אימייל לא תקינה';
      case 'weak-password':
        return 'סיסמה חלשה מדי';
      case 'network-request-failed':
        return 'בעיית רשת. בדוק/י אינטרנט ונסה/י שוב';
      default:
        return 'הרשמה נכשלה: ${e.message ?? e.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surfaceAlabaster,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.secondarySlate,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'יצירת חשבון',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondarySlate,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'מלא/י את הפרטים כדי להירשם',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondarySlate.withOpacity(0.65),
                    ),
                  ),
                  const SizedBox(height: 28),

                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'שם מלא',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'אימייל',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'סיסמה',
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'אימות סיסמה',
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() =>
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ✅ Styled user type pills
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('בעל חיית מחמד'),
                          selected: _isPetOwnerSelected,
                          showCheckmark: true,
                          selectedColor: AppColors.primarySage.withOpacity(0.22),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _isPetOwnerSelected
                                ? AppColors.secondarySlate
                                : AppColors.secondarySlate.withOpacity(0.7),
                          ),
                          side: BorderSide(
                            color: _isPetOwnerSelected
                                ? AppColors.primarySage.withOpacity(0.55)
                                : Colors.black.withOpacity(0.08),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          onSelected: (_) =>
                              setState(() => _isPetOwnerSelected = true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('מטפל/ת'),
                          selected: !_isPetOwnerSelected,
                          showCheckmark: true,
                          selectedColor: AppColors.primarySage.withOpacity(0.22),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: !_isPetOwnerSelected
                                ? AppColors.secondarySlate
                                : AppColors.secondarySlate.withOpacity(0.7),
                          ),
                          side: BorderSide(
                            color: !_isPetOwnerSelected
                                ? AppColors.primarySage.withOpacity(0.55)
                                : Colors.black.withOpacity(0.08),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          onSelected: (_) =>
                              setState(() => _isPetOwnerSelected = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Text(
                    _isPetOwnerSelected
                        ? 'בחרת: בעל/ת חיית מחמד — תוכל/י לבקש טיולים ושמירה בזמן נסיעה.'
                        : 'בחרת: מטפל/ת — תוכל/י לקבל בקשות ולטייל (בהמשך עם אימות).',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondarySlate.withOpacity(0.65),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (v) =>
                            setState(() => _acceptTerms = v ?? false),
                      ),
                      Expanded(
                        child: Text(
                          'אני מאשר/ת את תנאי השימוש',
                          style: TextStyle(
                            color: AppColors.secondarySlate.withOpacity(0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primarySage,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'הרשמה',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
