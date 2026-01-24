import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // User type selector (kept simple as you had TODO)
  bool _isPetOwnerSelected = true;

  static const String _logTag = '[SignupScreen]';

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('$_logTag $message');
    if (error != null) debugPrint('$_logTag   error: $error');
    if (stackTrace != null) debugPrint('$_logTag   stackTrace: $stackTrace');
  }

  @override
  void initState() {
    super.initState();
    _log('initState');
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
          'email=$email, nameLength=${name.length}, passwordLength=${password.length}, userType=${_isPetOwnerSelected ? 'owner' : 'provider'}',
    );

    if (!_acceptTerms) {
      _showSnack('יש לאשר את תנאי השימוש', isError: true);
      _log('validation failed: terms not accepted');
      return;
    }

    if (name.isEmpty) {
      _showSnack('אנא הזן/י שם מלא', isError: true);
      _log('validation failed: empty name');
      return;
    }

    if (email.isEmpty) {
      _showSnack('אנא הזן/י כתובת אימייל', isError: true);
      _log('validation failed: empty email');
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      _showSnack('כתובת אימייל לא תקינה', isError: true);
      _log('validation failed: invalid email', error: email);
      return;
    }

    if (password.isEmpty) {
      _showSnack('אנא הזן/י סיסמה', isError: true);
      _log('validation failed: empty password');
      return;
    }

    if (password.length < 6) {
      _showSnack('הסיסמה חייבת להכיל לפחות 6 תווים', isError: true);
      _log('validation failed: password too short', error: password.length);
      return;
    }

    if (password != confirmPassword) {
      _showSnack('הסיסמאות אינן תואמות', isError: true);
      _log('validation failed: password mismatch');
      return;
    }

    setState(() => _isLoading = true);

    try {
      _log('calling FirebaseAuth.createUserWithEmailAndPassword');
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _log('signup success: uid=${credential.user?.uid}');

      // Optional: set display name (nice to have)
      try {
        await credential.user?.updateDisplayName(name);
        _log('displayName updated');
      } catch (e, st) {
        // Not critical for signup success
        _log('failed to update displayName', error: e, stackTrace: st);
      }

      if (!mounted) return;

      _showSnack('החשבון נוצר בהצלחה ✅');

      // For now: go back to login
      try {
        Navigator.pop(context);
        _log('Navigator.pop -> back to login');
      } catch (e, st) {
        _log('Navigator.pop failed', error: e, stackTrace: st);
      }
    } on FirebaseAuthException catch (e) {
      _log('FirebaseAuthException during signup: ${e.code} | ${e.message}');
      if (!mounted) return;
      _showSnack(_friendlyRegisterErrorHe(e), isError: true);
    } catch (e, st) {
      _log('Unexpected error during signup', error: e, stackTrace: st);
      if (!mounted) return;
      _showSnack('שגיאה לא צפויה. נסה/י שוב.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    _log('SnackBar: $msg');
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
      case 'operation-not-allowed':
        return 'פעולה זו אינה זמינה כרגע';
      default:
        return 'הרשמה נכשלה: ${e.message ?? e.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    onPressed: () {
                      _log('back pressed');
                      try {
                        Navigator.pop(context);
                      } catch (e, st) {
                        _log('Navigator.pop failed', error: e, stackTrace: st);
                      }
                    },
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

                // Name
                TextField(
                  controller: _nameController,
                  onChanged: (v) => _log('name changed', error: 'length=${v.length}'),
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

                // Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (v) => _log('email changed', error: 'length=${v.length}'),
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

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  onChanged: (v) => _log('password changed', error: 'length=${v.length}'),
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
                      onPressed: () {
                        setState(() => _isPasswordVisible = !_isPasswordVisible);
                        _log('toggle password visibility', error: _isPasswordVisible);
                      },
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Confirm Password
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  onChanged: (v) =>
                      _log('confirmPassword changed', error: 'length=${v.length}'),
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
                      onPressed: () {
                        setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                        _log('toggle confirm password visibility',
                            error: _isConfirmPasswordVisible);
                      },
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Simple user type selector
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('בעל חיית מחמד'),
                        selected: _isPetOwnerSelected,
                        onSelected: (v) {
                          setState(() => _isPetOwnerSelected = true);
                          _log('userType selected: owner');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('מטפל/ת'),
                        selected: !_isPetOwnerSelected,
                        onSelected: (v) {
                          setState(() => _isPetOwnerSelected = false);
                          _log('userType selected: provider');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Terms
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (v) {
                        setState(() => _acceptTerms = v ?? false);
                        _log('terms toggled', error: _acceptTerms);
                      },
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
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
