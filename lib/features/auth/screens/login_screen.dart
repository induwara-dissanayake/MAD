import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(); // NIC or Email
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  /// Determine email to use for Firebase Auth.
  /// If the input looks like a real email, use it directly.
  /// Otherwise treat it as a NIC and derive the synthetic email.
  String _resolveEmail(String input) {
    final trimmed = input.trim();
    final isEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(trimmed);
    if (isEmail) return trimmed;
    return Validators.nicToEmail(trimmed);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final email = _resolveEmail(_identifierController.text);
      await ref
          .read(authServiceProvider)
          .signInWithEmail(email, _passwordController.text);
      if (mounted) {
        context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message;
        switch (e.code) {
          case 'user-not-found':
            message =
                'No account found. Please contact your Grama Niladhari office.';
            break;
          case 'wrong-password':
            message = 'Incorrect password. Please try again.';
            break;
          case 'invalid-credential':
            message = 'Invalid credentials. Please check and try again.';
            break;
          case 'operation-not-allowed':
            message =
                'Sign-in is not enabled. Please contact the administrator.';
            break;
          default:
            message = 'Login failed: ${e.message}';
        }
        _showError(message);
      }
    } catch (e) {
      if (mounted) _showError('Login failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome text
                        Text('Welcome Back', style: AppTextStyles.h1),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in with your NIC number or email address.',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 32),

                        // NIC or Email field
                        _buildFieldLabel('NIC Number or Email'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _identifierController,
                          hint: 'Enter NIC (e.g., 200012345678) or email',
                          prefixIcon: Icons.badge_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'NIC number or email is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password field
                        _buildFieldLabel('Password'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _passwordController,
                          hint: 'Enter your password',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // Sign-in button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textOnPrimary,
                              elevation: 2,
                              shadowColor: AppColors.primary.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text('Sign In', style: AppTextStyles.button),
                          ),
                        ),

                        const SizedBox(height: 32),
                        _buildInfoBox(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 36),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Village Connect',
            style: AppTextStyles.h2.copyWith(
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Grama Niladhari Services Portal',
            style: AppTextStyles.small.copyWith(
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Official Government Platform',
                  style: AppTextStyles.small.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(label, style: AppTextStyles.label);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        prefixIcon: Icon(prefixIcon, color: AppColors.textMuted, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surfaceGrey,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.info,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'First time accessing?',
                  style: AppTextStyles.captionMedium
                      .copyWith(color: AppColors.info),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your account is created by your Grama Niladhari officer or an authorized resident. '
                  'Check your email for your login credentials.',
                  style:
                      AppTextStyles.small.copyWith(color: AppColors.info),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
