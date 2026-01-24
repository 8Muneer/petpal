import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/auth/presentation/signup_screen.dart';
import 'package:petpal/features/auth/presentation/guest_home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  static const String _logTag = '[LoginScreen]';

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack('אנא מלא/י אימייל וסיסמה');
      _log('validation failed: empty email/password');
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      _showSnack('אנא הזן/י כתובת אימייל תקינה');
      _log('validation failed: invalid email', error: email);
      return;
    }

    _log('attempting login', error: 'email=$email, passwordLength=${password.length}');
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // ✅ Navigate to GuestHomeScreen after successful login
      try {
        _log('login success, navigating to GuestHomeScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GuestHomeScreen()),
        );
      } catch (e, st) {
        _log('navigation failed after login', error: e, stackTrace: st);
        if (!mounted) return;
        _showSnack('התחברות הצליחה, אבל הניווט נכשל. נסה/י שוב.');
      }
    } on FirebaseAuthException catch (e) {
      _log('FirebaseAuthException during login: ${e.code} | ${e.message}');
      if (!mounted) return;
      _showSnack(_friendlyAuthErrorHe(e));
    } catch (e, st) {
      _log('Unexpected error during login', error: e, stackTrace: st);
      if (!mounted) return;
      _showSnack('שגיאה לא צפויה. נסה/י שוב.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    _log('SnackBar: $msg');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  String _friendlyAuthErrorHe(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'כתובת אימייל לא תקינה';
      case 'user-disabled':
        return 'המשתמש חסום';
      case 'user-not-found':
        return 'לא נמצא משתמש עם האימייל הזה';
      case 'wrong-password':
        return 'סיסמה שגויה';
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'אימייל או סיסמה לא נכונים';
      case 'network-request-failed':
        return 'בעיית רשת. בדוק/י אינטרנט ונסה/י שוב';
      case 'too-many-requests':
        return 'יותר מדי ניסיונות. נסה/י שוב מאוחר יותר';
      default:
        return 'התחברות נכשלה: ${e.message ?? e.code}';
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
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primarySage.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.pets,
                      size: 40,
                      color: AppColors.primarySage,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'ברוכים הבאים 👋',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondarySlate,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'התחברו כדי להמשיך',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondarySlate.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 32),

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
                const SizedBox(height: 16),

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
                const SizedBox(height: 24),

                // Login button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
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
                            'התחברות',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'אין לך חשבון? ',
                      style: TextStyle(
                        color: AppColors.secondarySlate.withOpacity(0.65),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _log('go to signup');
                        try {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignupScreen()),
                          );
                        } catch (e, st) {
                          _log('navigation to SignupScreen failed', error: e, stackTrace: st);
                          _showSnack('הניווט נכשל. נסה/י שוב.');
                        }
                      },
                      child: const Text(
                        'הרשמה',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primarySage,
                        ),
                      ),
                    ),
                  ],
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
