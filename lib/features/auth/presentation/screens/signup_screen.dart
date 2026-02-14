import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'package:petpal/core/widgets/glass_card.dart';
import 'package:petpal/core/widgets/input_field.dart';
import 'package:petpal/core/widgets/primary_gradient_button.dart';
import 'package:petpal/core/widgets/petpal_scaffold.dart';

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

  bool _isLoading = false;
  bool _acceptTerms = false;

  // Role selection (PetOwner vs ServiceProvider)
  bool _isPetOwnerSelected = true;

  final _auth = FirebaseAuth.instance;
  final _usersRef = FirebaseFirestore.instance.collection('users');

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('[SignupScreen] $message');
    if (error != null) {
      debugPrint('[SignupScreen] error: $error');
    }
    if (stackTrace != null) {
      debugPrint('[SignupScreen] stackTrace: $stackTrace');
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
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

  String _friendlyRegisterErrorHe(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return '\u05d4\u05d0\u05d9\u05de\u05d9\u05d9\u05dc \u05db\u05d1\u05e8 \u05d1\u05e9\u05d9\u05de\u05d5\u05e9. \u05e0\u05e1\u05d4/\u05d9 \u05dc\u05d4\u05ea\u05d7\u05d1\u05e8 \u05d0\u05d5 \u05d4\u05e9\u05ea\u05de\u05e9/\u05d9 \u05d1\u05d0\u05d9\u05de\u05d9\u05d9\u05dc \u05d0\u05d7\u05e8.';
      case 'invalid-email':
        return '\u05db\u05ea\u05d5\u05d1\u05ea \u05d4\u05d0\u05d9\u05de\u05d9\u05d9\u05dc \u05dc\u05d0 \u05ea\u05e7\u05d9\u05e0\u05d4.';
      case 'weak-password':
        return '\u05d4\u05e1\u05d9\u05e1\u05de\u05d4 \u05d7\u05dc\u05e9\u05d4 \u05de\u05d3\u05d9. \u05e0\u05e1\u05d4/\u05d9 \u05e1\u05d9\u05e1\u05de\u05d4 \u05d7\u05d6\u05e7\u05d4 \u05d9\u05d5\u05ea\u05e8.';
      case 'operation-not-allowed':
        return '\u05e9\u05d9\u05d8\u05ea \u05d4\u05d4\u05e8\u05e9\u05de\u05d4 \u05d4\u05d6\u05d5 \u05dc\u05d0 \u05d6\u05de\u05d9\u05e0\u05d4 \u05db\u05e8\u05d2\u05e2.';
      case 'network-request-failed':
        return '\u05d1\u05e2\u05d9\u05d9\u05ea \u05e8\u05e9\u05ea. \u05d1\u05d3\u05d5\u05e7/\u05d9 \u05d0\u05ea \u05d4\u05d7\u05d9\u05d1\u05d5\u05e8 \u05d5\u05e0\u05e1\u05d4/\u05d9 \u05e9\u05d5\u05d1.';
      default:
        return '\u05e9\u05d2\u05d9\u05d0\u05d4 \u05d1\u05d4\u05e8\u05e9\u05de\u05d4. \u05e0\u05e1\u05d4/\u05d9 \u05e9\u05d5\u05d1.';
    }
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    _log(
      'attempting signup',
      error:
          'email=$email, nameLength=${name.length}, passwordLength=${password.length}, role=${_isPetOwnerSelected ? 'petOwner' : 'serviceProvider'}',
    );

    if (!_acceptTerms) {
      _showSnack('\u05d9\u05e9 \u05dc\u05d0\u05e9\u05e8 \u05d0\u05ea \u05ea\u05e0\u05d0\u05d9 \u05d4\u05e9\u05d9\u05de\u05d5\u05e9', isError: true);
      return;
    }
    if (name.isEmpty) {
      _showSnack('\u05d0\u05e0\u05d0 \u05d4\u05d6\u05df/\u05d9 \u05e9\u05dd \u05de\u05dc\u05d0', isError: true);
      return;
    }
    if (email.isEmpty) {
      _showSnack('\u05d0\u05e0\u05d0 \u05d4\u05d6\u05df/\u05d9 \u05db\u05ea\u05d5\u05d1\u05ea \u05d0\u05d9\u05de\u05d9\u05d9\u05dc', isError: true);
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      _showSnack('\u05db\u05ea\u05d5\u05d1\u05ea \u05d0\u05d9\u05de\u05d9\u05d9\u05dc \u05dc\u05d0 \u05ea\u05e7\u05d9\u05e0\u05d4', isError: true);
      return;
    }

    if (password.isEmpty) {
      _showSnack('\u05d0\u05e0\u05d0 \u05d4\u05d6\u05df/\u05d9 \u05e1\u05d9\u05e1\u05de\u05d4', isError: true);
      return;
    }
    if (password.length < 6) {
      _showSnack('\u05d4\u05e1\u05d9\u05e1\u05de\u05d4 \u05d7\u05d9\u05d9\u05d1\u05ea \u05dc\u05d4\u05db\u05d9\u05dc \u05dc\u05e4\u05d7\u05d5\u05ea 6 \u05ea\u05d5\u05d5\u05d9\u05dd', isError: true);
      return;
    }
    if (password != confirmPassword) {
      _showSnack('\u05d4\u05e1\u05d9\u05e1\u05de\u05d0\u05d5\u05ea \u05d0\u05d9\u05e0\u05df \u05ea\u05d5\u05d0\u05de\u05d5\u05ea', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;

      _log('signup success uid=$uid');

      // display name (non-fatal)
      try {
        await credential.user?.updateDisplayName(name);
      } catch (_) {}

      // Save role in Firestore (non-fatal)
      if (uid != null) {
        try {
          await _usersRef.doc(uid).set(
            {
              'uid': uid,
              'name': name,
              'email': email,
              'role': _isPetOwnerSelected ? 'petOwner' : 'serviceProvider',
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

      // Sign out so the user must log in manually
      await _auth.signOut();

      if (!mounted) return;

      _showSnack('\u05d4\u05d7\u05e9\u05d1\u05d5\u05df \u05e0\u05d5\u05e6\u05e8 \u05d1\u05d4\u05e6\u05dc\u05d7\u05d4 \u2705 \u05e0\u05d0 \u05d4\u05ea\u05d7\u05d1\u05e8/\u05d9');

      // Navigate to login screen
      context.go('/login');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showSnack(_friendlyRegisterErrorHe(e), isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('\u05e9\u05d2\u05d9\u05d0\u05d4 \u05dc\u05d0 \u05e6\u05e4\u05d5\u05d9\u05d4. \u05e0\u05e1\u05d4/\u05d9 \u05e9\u05d5\u05d1.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '\u05d9\u05e6\u05d9\u05e8\u05ea \u05d7\u05e9\u05d1\u05d5\u05df',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Role selection
                GlassCard(
                  useBlur: false,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '\u05d1\u05d7\u05e8/\u05d9 \u05e1\u05d5\u05d2 \u05de\u05e9\u05ea\u05de\u05e9',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('\u05d1\u05e2\u05dc \u05d7\u05d9\u05d9\u05ea \u05de\u05d7\u05de\u05d3'),
                              selected: _isPetOwnerSelected,
                              onSelected: (v) {
                                setState(() => _isPetOwnerSelected = true);
                              },
                              selectedColor: const Color(0xFF0F766E).withOpacity(0.16),
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: _isPetOwnerSelected
                                    ? const Color(0xFF0F766E)
                                    : const Color(0xFF334155),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: _isPetOwnerSelected
                                      ? const Color(0xFF0F766E).withOpacity(0.35)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('\u05de\u05d8\u05e4\u05dc/\u05ea'),
                              selected: !_isPetOwnerSelected,
                              onSelected: (v) {
                                setState(() => _isPetOwnerSelected = false);
                              },
                              selectedColor: const Color(0xFF0EA5E9).withOpacity(0.16),
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: !_isPetOwnerSelected
                                    ? const Color(0xFF0EA5E9)
                                    : const Color(0xFF334155),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: !_isPetOwnerSelected
                                      ? const Color(0xFF0EA5E9).withOpacity(0.35)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isPetOwnerSelected
                            ? '\u05dc\u05d1\u05e2\u05dc\u05d9 \u05d7\u05d9\u05d5\u05ea \u05de\u05d7\u05de\u05d3 \u05e9\u05de\u05d7\u05e4\u05e9\u05d9\u05dd \u05d3\u05d5\u05d2-\u05d5\u05d5\u05e7\u05e8/\u05e1\u05d9\u05d8\u05e8'
                            : '\u05dc\u05de\u05d8\u05e4\u05dc\u05d9\u05dd/\u05d3\u05d5\u05d2-\u05d5\u05d5\u05e7\u05e8\u05d9\u05dd \u05e9\u05de\u05e6\u05d9\u05e2\u05d9\u05dd \u05e9\u05d9\u05e8\u05d5\u05ea\u05d9\u05dd',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155).withOpacity(0.80),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                GlassCard(
                  useBlur: false,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      InputField(
                        controller: _nameController,
                        label: '\u05e9\u05dd \u05de\u05dc\u05d0',
                        hint: '\u05d4\u05d6\u05df/\u05d9 \u05e9\u05dd',
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 12),
                      InputField(
                        controller: _emailController,
                        label: '\u05d0\u05d9\u05de\u05d9\u05d9\u05dc',
                        hint: 'name@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      InputField(
                        controller: _passwordController,
                        label: '\u05e1\u05d9\u05e1\u05de\u05d4',
                        hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                        icon: Icons.lock_outline,
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      InputField(
                        controller: _confirmPasswordController,
                        label: '\u05d0\u05d9\u05de\u05d5\u05ea \u05e1\u05d9\u05e1\u05de\u05d4',
                        hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                        icon: Icons.lock_reset_outlined,
                        obscureText: true,
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                            activeColor: const Color(0xFF0F766E),
                          ),
                          Expanded(
                            child: Text(
                              '\u05d0\u05e0\u05d9 \u05de\u05d0\u05e9\u05e8/\u05ea \u05d0\u05ea \u05ea\u05e0\u05d0\u05d9 \u05d4\u05e9\u05d9\u05de\u05d5\u05e9 \u05d5\u05d4\u05de\u05d3\u05d9\u05e0\u05d9\u05d5\u05ea',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF334155).withOpacity(0.90),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      PrimaryGradientButton(
                        text: _isLoading ? '\u05d9\u05d5\u05e6\u05e8 \u05d7\u05e9\u05d1\u05d5\u05df...' : '\u05e6\u05d5\u05e8 \u05d7\u05e9\u05d1\u05d5\u05df',
                        icon: _isLoading ? Icons.hourglass_top_rounded : Icons.check_rounded,
                        onTap: _isLoading ? null : _handleSignup,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '\u05db\u05d1\u05e8 \u05d9\u05e9 \u05dc\u05da \u05d7\u05e9\u05d1\u05d5\u05df?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155).withOpacity(0.85),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/login'),
                      child: const Text(
                        '\u05d4\u05ea\u05d7\u05d1\u05e8/\u05d9',
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
