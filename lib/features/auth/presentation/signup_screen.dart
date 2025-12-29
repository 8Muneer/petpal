import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/features/auth/presentation/auth_state.dart';
import 'package:petpal/screens/guest_home_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;
  int _selectedUserType = 0; // 0 = Pet Owner, 1 = Sitter

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignup() {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('יש לאשר את תנאי השימוש'),
          backgroundColor: AppColors.alertCoral,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authStateProvider.notifier).signUp(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
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
            // Navigate to home on successful signup
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
                  const SizedBox(height: 40),
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
                  const SizedBox(height: 12),
                  // Header
                  Text(
                    'צור חשבון חדש',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondarySlate,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'הצטרף למשפחת PetPal והתחל לטפל בחיית המחמד שלך',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondarySlate.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // User type selector
                  _buildUserTypeSelector(),
                  const SizedBox(height: 24),
                  // Name field
                  _buildInputField(
                    controller: _nameController,
                    label: 'שם מלא',
                    hint: 'הכנס את שמך',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'נא להזין שם מלא';
                      }
                      if (value.length < 2) {
                        return 'השם חייב להכיל לפחות 2 תווים';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
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
                    hint: 'לפחות 8 תווים',
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
                      if (value.length < 8) {
                        return 'הסיסמה חייבת להכיל לפחות 8 תווים';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Confirm password field
                  _buildInputField(
                    controller: _confirmPasswordController,
                    label: 'אימות סיסמה',
                    hint: 'הכנס את הסיסמה שוב',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isPasswordVisible: _isConfirmPasswordVisible,
                    onVisibilityToggle: () {
                      setState(() => _isConfirmPasswordVisible =
                          !_isConfirmPasswordVisible);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'נא לאמת את הסיסמה';
                      }
                      if (value != _passwordController.text) {
                        return 'הסיסמאות אינן תואמות';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Terms checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (value) =>
                            setState(() => _acceptTerms = value ?? false),
                        activeColor: AppColors.primarySage,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondarySlate.withOpacity(0.7),
                            ),
                            children: [
                              const TextSpan(text: 'אני מסכים ל'),
                              TextSpan(
                                text: 'תנאי השימוש',
                                style: TextStyle(
                                  color: AppColors.primarySage,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(text: ' ו'),
                              TextSpan(
                                text: 'מדיניות הפרטיות',
                                style: TextStyle(
                                  color: AppColors.primarySage,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Signup button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleSignup,
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
                              'צור חשבון',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'כבר יש לך חשבון?',
                        style: TextStyle(
                          color: AppColors.secondarySlate.withOpacity(0.7),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'התחבר כאן',
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

  Widget _buildUserTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.warmMist,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeOption('בעל חיית מחמד', Icons.pets, 0),
          ),
          Expanded(
            child: _buildTypeOption('מטפל', Icons.volunteer_activism, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(String label, IconData icon, int index) {
    final isSelected = _selectedUserType == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedUserType = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySage : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.white : AppColors.secondarySlate,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.secondarySlate,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
}
