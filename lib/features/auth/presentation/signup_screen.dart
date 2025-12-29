import 'package:flutter/material.dart';
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

    setState(() => _isLoading = true);
    // TODO: Integrate with AuthState provider
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
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
                ),
                const SizedBox(height: 16),
                // Email field
                _buildInputField(
                  controller: _emailController,
                  label: 'כתובת אימייל',
                  hint: 'example@email.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
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
                    setState(() =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
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
                    onPressed: _isLoading ? null : _handleSignup,
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
                    child: _isLoading
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
            child: _buildTypeOption('בעל חיית מחמד', Icons.pets, true),
          ),
          Expanded(
            child: _buildTypeOption('מטפל', Icons.volunteer_activism, false),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        // TODO: Handle user type selection
      },
      child: Container(
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
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword && !isPasswordVisible,
            textAlign: TextAlign.right,
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
