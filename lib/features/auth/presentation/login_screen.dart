import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/auth/presentation/auth_state.dart';
import 'package:petpal/features/auth/presentation/signup_screen.dart';
import 'package:petpal/screens/guest_home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authStateProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Listen for auth state changes
    ref.listen<AsyncValue>(authStateProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null) {
            // Navigate to home on successful login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const GuestHomeScreen()),
            );
          }
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppColors.alertCoral,
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.surfaceAlabaster,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  // Back button
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.secondarySlate,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Header
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primarySage.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.pets,
                        size: 40,
                        color: AppColors.primarySage,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ברוכים השבים!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondarySlate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'התחבר לחשבון שלך כדי להמשיך',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondarySlate.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Email field
                  _buildInputField(
                    controller: _emailController,
                    label: 'כתובת אימייל',
                    hint: 'example@email.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'נא להזין כתובת אימייל';
                      }
                      if (!value.contains('@')) {
                        return 'כתובת אימייל לא תקינה';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Password field
                  _buildInputField(
                    controller: _passwordController,
                    label: 'סיסמה',
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    onVisibilityToggle: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'נא להזין סיסמה';
                      }
                      if (value.length < 6) {
                        return 'הסיסמה חייבת להכיל לפחות 6 תווים';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Forgot password
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Navigate to forgot password
                      },
                      child: Text(
                        'שכחת סיסמה?',
                        style: TextStyle(
                          color: AppColors.primarySage,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Login button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primarySage,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor:
                            AppColors.primarySage.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.superCurveRadius),
                        ),
                        elevation: 0,
                      ),
                      child: authState.isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white),
                              ),
                            )
                          : const Text(
                              'התחבר',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Divider
                  Row(
                    children: [
                      Expanded(
                          child: Divider(
                              color:
                                  AppColors.secondarySlate.withOpacity(0.2))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'או',
                          style: TextStyle(
                            color: AppColors.secondarySlate.withOpacity(0.5),
                          ),
                        ),
                      ),
                      Expanded(
                          child: Divider(
                              color:
                                  AppColors.secondarySlate.withOpacity(0.2))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Social login buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialButton(Icons.g_mobiledata, 'Google'),
                      const SizedBox(width: 16),
                      _buildSocialButton(Icons.apple, 'Apple'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'אין לך חשבון?',
                        style: TextStyle(
                          color: AppColors.secondarySlate.withOpacity(0.7),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignupScreen()),
                          );
                        },
                        child: Text(
                          'הירשם עכשיו',
                          style: TextStyle(
                            color: AppColors.primarySage,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onVisibilityToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.secondarySlate,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.warmMist,
            borderRadius: BorderRadius.circular(AppTheme.superCurveRadius),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword && !isPasswordVisible,
            textAlign: TextAlign.right,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.secondarySlate.withOpacity(0.4),
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              prefixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.secondarySlate.withOpacity(0.5),
                      ),
                      onPressed: onVisibilityToggle,
                    )
                  : null,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(icon, color: AppColors.primarySage),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, String label) {
    return InkWell(
      onTap: () {
        // TODO: Implement social login
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondarySlate.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.secondarySlate),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.secondarySlate,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
