import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/utils/validators.dart';
import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/input_field.dart';
import 'package:petpal/core/widgets/primary_gradient_button.dart';
import 'package:petpal/core/widgets/petpal_scaffold.dart';

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

  void _showSnack(String msg, {bool isError = false}) {
    _log('SnackBar: $msg');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFB91C1C) : const Color(0xFF0F766E),
      ),
    );
  }

  String _friendlyAuthErrorHe(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return '\u05db\u05ea\u05d5\u05d1\u05ea \u05d0\u05d9\u05de\u05d9\u05d9\u05dc \u05dc\u05d0 \u05ea\u05e7\u05d9\u05e0\u05d4';
      case 'user-disabled':
        return '\u05d4\u05de\u05e9\u05ea\u05de\u05e9 \u05d7\u05e1\u05d5\u05dd';
      case 'user-not-found':
        return '\u05dc\u05d0 \u05e0\u05de\u05e6\u05d0 \u05de\u05e9\u05ea\u05de\u05e9 \u05e2\u05dd \u05d0\u05d9\u05de\u05d9\u05d9\u05dc \u05d6\u05d4';
      case 'wrong-password':
        return '\u05e1\u05d9\u05e1\u05de\u05d4 \u05e9\u05d2\u05d5\u05d9\u05d4';
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return '\u05d0\u05d9\u05de\u05d9\u05d9\u05dc \u05d0\u05d5 \u05e1\u05d9\u05e1\u05de\u05d4 \u05e9\u05d2\u05d5\u05d9\u05d9\u05dd';
      case 'network-request-failed':
        return '\u05d1\u05e2\u05d9\u05d9\u05ea \u05e8\u05e9\u05ea. \u05d1\u05d3\u05d5\u05e7/\u05d9 \u05d0\u05ea \u05d4\u05d7\u05d9\u05d1\u05d5\u05e8 \u05d5\u05e0\u05e1\u05d4/\u05d9 \u05e9\u05d5\u05d1';
      case 'too-many-requests':
        return '\u05d9\u05d5\u05ea\u05e8 \u05de\u05d3\u05d9 \u05e0\u05d9\u05e1\u05d9\u05d5\u05e0\u05d5\u05ea. \u05e0\u05e1\u05d4/\u05d9 \u05e9\u05d5\u05d1 \u05de\u05d0\u05d5\u05d7\u05e8 \u05d9\u05d5\u05ea\u05e8';
      default:
        return '\u05e9\u05d2\u05d9\u05d0\u05d4 \u05d1\u05d4\u05ea\u05d7\u05d1\u05e8\u05d5\u05ea: ${e.message ?? e.code}';
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack('\u05d0\u05e0\u05d0 \u05de\u05dc\u05d0/\u05d9 \u05d0\u05d9\u05de\u05d9\u05d9\u05dc \u05d5\u05e1\u05d9\u05e1\u05de\u05d4', isError: true);
      _log('validation failed: empty email/password');
      return;
    }

    if (!Validators.isValidEmail(email)) {
      _showSnack('\u05d0\u05e0\u05d0 \u05d4\u05d6\u05df/\u05d9 \u05db\u05ea\u05d5\u05d1\u05ea \u05d0\u05d9\u05de\u05d9\u05d9\u05dc \u05ea\u05e7\u05d9\u05e0\u05d4', isError: true);
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

      _log('login success, navigating to AuthGate (/) for role-based routing');
      context.go('/');
    } on FirebaseAuthException catch (e) {
      _log('FirebaseAuthException during login: ${e.code} | ${e.message}');
      if (!mounted) return;
      _showSnack(_friendlyAuthErrorHe(e), isError: true);
    } catch (e, st) {
      _log('Unexpected error during login', error: e, stackTrace: st);
      if (!mounted) return;
      _showSnack('\u05e9\u05d2\u05d9\u05d0\u05d4 \u05dc\u05d0 \u05e6\u05e4\u05d5\u05d9\u05d4. \u05e0\u05e1\u05d4/\u05d9 \u05e9\u05d5\u05d1.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('\u05d0\u05e0\u05d0 \u05d4\u05d6\u05df/\u05d9 \u05d0\u05d9\u05de\u05d9\u05d9\u05dc \u05dc\u05d0\u05d9\u05e4\u05d5\u05e1 \u05e1\u05d9\u05e1\u05de\u05d4', isError: true);
      return;
    }

    if (!Validators.isValidEmail(email)) {
      _showSnack('\u05d0\u05e0\u05d0 \u05d4\u05d6\u05df/\u05d9 \u05db\u05ea\u05d5\u05d1\u05ea \u05d0\u05d9\u05de\u05d9\u05d9\u05dc \u05ea\u05e7\u05d9\u05e0\u05d4', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _showSnack('\u05e7\u05d9\u05e9\u05d5\u05e8 \u05dc\u05d0\u05d9\u05e4\u05d5\u05e1 \u05e1\u05d9\u05e1\u05de\u05d4 \u05e0\u05e9\u05dc\u05d7 \u05dc\u05d0\u05d9\u05de\u05d9\u05d9\u05dc');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showSnack(_friendlyAuthErrorHe(e), isError: true);
    } catch (_) {
      if (!mounted) return;
      _showSnack('\u05e9\u05d2\u05d9\u05d0\u05d4 \u05dc\u05d0 \u05e6\u05e4\u05d5\u05d9\u05d4. \u05e0\u05e1\u05d4/\u05d9 \u05e9\u05d5\u05d1.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                // Header row
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '\u05d4\u05ea\u05d7\u05d1\u05e8\u05d5\u05ea',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Small hero icon
                Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: Colors.white.withOpacity(0.65),
                      border: Border.all(color: Colors.white.withOpacity(0.48)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 26,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      size: 42,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  '\u05e9\u05de\u05d7\u05d9\u05dd \u05e9\u05d7\u05d6\u05e8\u05ea!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\u05d4\u05ea\u05d7\u05d1\u05e8/\u05d9 \u05db\u05d3\u05d9 \u05dc\u05d4\u05de\u05e9\u05d9\u05da',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155).withOpacity(0.80),
                  ),
                ),

                const SizedBox(height: 14),

                // Glass card form
                GlassCard(
                  useBlur: false,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      InputField(
                        controller: _emailController,
                        label: '\u05d0\u05d9\u05de\u05d9\u05d9\u05dc',
                        hint: 'name@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),

                      // password with toggle
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: '\u05e1\u05d9\u05e1\u05de\u05d4',
                          hintText: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible,
                            ),
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.65),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: const Color(0xFFE2E8F0).withOpacity(0.9),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF0F766E),
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _isLoading ? null : _handleForgotPassword,
                          child: Text(
                            '\u05e9\u05db\u05d7\u05ea \u05e1\u05d9\u05e1\u05de\u05d4?',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F766E).withOpacity(0.95),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      PrimaryGradientButton(
                        text: _isLoading ? '\u05de\u05ea\u05d7\u05d1\u05e8...' : '\u05d4\u05ea\u05d7\u05d1\u05e8\u05d5\u05ea',
                        icon: _isLoading
                            ? Icons.hourglass_top_rounded
                            : Icons.login_rounded,
                        onTap: _isLoading ? null : _handleLogin,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '\u05d0\u05d9\u05df \u05dc\u05da \u05d7\u05e9\u05d1\u05d5\u05df?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155).withOpacity(0.85),
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => context.push('/signup'),
                      child: const Text(
                        '\u05d4\u05e8\u05e9\u05de\u05d4',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
