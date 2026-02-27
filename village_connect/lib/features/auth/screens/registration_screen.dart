import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/vc_components.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() =>
      _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  int _currentStep = 0;
  final int _totalSteps = 4;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _nicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  String _selectedVillage = '';
  String _selectedDistrict = '';

  bool _isLoading = false;
  bool _accountCreated = false;
  String? _errorMessage;

  final List<String> _stepLabels = [
    'Personal Info',
    'Address',
    'Password',
    'Google',
  ];

  final List<String> _villages = [
    'Welivita South',
    'Welivita North',
    'Kaduwela East',
    'Kaduwela West',
    'Malabe Central',
  ];

  final List<String> _districts = [
    'Colombo',
    'Gampaha',
    'Kandy',
    'Kalutara',
    'Matara',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _nicController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_currentStep == 0 && !_formKey.currentState!.validate()) return;

    // At the end of Step 2 (Password), create the account
    if (_currentStep == 2) {
      await _createAccount();
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_accountCreated) return;
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _createAccount() async {
    if (!_agreedToTerms) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final nic = _nicController.text.trim();
      final email = Validators.nicToEmail(nic);
      final password = _passwordController.text;

      // Check if NIC already registered in Firestore
      final userService = ref.read(userServiceProvider);
      final alreadyExists = await userService.isNicRegistered(nic);
      if (alreadyExists) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'This NIC is already registered. Please log in instead.';
        });
        return;
      }

      // Create Firebase Auth account
      final authService = ref.read(authServiceProvider);
      final credential =
          await authService.createAccountWithEmail(email, password);
      final uid = credential.user!.uid;

      // Set display name
      await authService.updateDisplayName(_fullNameController.text.trim());

      // Create Firestore user profile
      final userModel = UserModel(
        uid: uid,
        fullName: _fullNameController.text.trim(),
        nic: nic,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        village: _selectedVillage,
        district: _selectedDistrict,
        createdAt: DateTime.now(),
      );
      await userService.createUserProfile(userModel);

      setState(() {
        _isLoading = false;
        _accountCreated = true;
        _currentStep = 3;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _mapAuthError(e.code);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().contains('operation-not-allowed') ||
                e.toString().contains('sign-in provider is disabled')
            ? 'Email/Password sign-in is not enabled. Please contact the administrator to enable it in the Firebase Console.'
            : 'Registration failed. Please try again.';
      });
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This NIC is already registered. Please log in instead.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger one.';
      case 'invalid-email':
        return 'Internal error: invalid email format.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled. Please contact the administrator to enable it in the Firebase Console.';
      default:
        return 'Registration failed ($code). Please try again.';
    }
  }

  Future<void> _linkGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final googleEmail = await authService.linkGoogleAccount();

      if (googleEmail != null) {
        final uid = authService.currentUser!.uid;
        await ref
            .read(userServiceProvider)
            .updateGoogleEmail(uid, googleEmail);
      }

      if (mounted) context.go('/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.code == 'credential-already-in-use'
            ? 'This Google account is already linked to another user.'
            : 'Failed to link Google account: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to link Google account. You can do this later in Settings.';
      });
    }
  }

  void _skipGoogleLink() {
    context.go('/home');
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _fullNameController.text.trim().isNotEmpty &&
            _nicController.text.trim().isNotEmpty &&
            _phoneController.text.trim().isNotEmpty;
      case 1:
        return _addressController.text.trim().isNotEmpty &&
            _selectedVillage.isNotEmpty &&
            _selectedDistrict.isNotEmpty;
      case 2:
        return _passwordController.text.trim().length >= 8 &&
            _confirmPasswordController.text.trim() ==
                _passwordController.text.trim() &&
            _agreedToTerms;
      case 3:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            if (_accountCreated) {
              context.go('/home');
            } else {
              context.pop();
            }
          },
        ),
        title: Text('Create Account', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: AppColors.divider),
          VcStepIndicator(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
            labels: _stepLabels,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildCurrentStep(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildAddressStep();
      case 2:
        return _buildPasswordStep();
      case 3:
        return _buildGoogleLinkStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: Personal Info ─────────────────────────────────────────────
  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personal Details', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text(
              'Enter your details as per your NIC.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 24),
            _buildFormField(
              label: 'Full Name',
              controller: _fullNameController,
              hint: 'Enter your full name',
              icon: Icons.person_outline_rounded,
              validator: Validators.validateFullName,
            ),
            const SizedBox(height: 18),
            _buildFormField(
              label: 'NIC Number',
              controller: _nicController,
              hint: 'e.g., 200012345678',
              icon: Icons.badge_outlined,
              validator: Validators.validateNic,
            ),
            const SizedBox(height: 18),
            _buildFormField(
              label: 'Phone Number',
              controller: _phoneController,
              hint: '+94 77 123 4567',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhone,
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Address ───────────────────────────────────────────────────
  Widget _buildAddressStep() {
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Address & Village', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            'Your village information helps route services correctly.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 24),
          _buildFormField(
            label: 'Home Address',
            controller: _addressController,
            hint: 'Enter your permanent address',
            icon: Icons.location_on_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 18),
          _buildDropdownField(
            label: 'Village / Division',
            value: _selectedVillage,
            items: _villages,
            icon: Icons.holiday_village_outlined,
            onChanged: (v) => setState(() => _selectedVillage = v ?? ''),
          ),
          const SizedBox(height: 18),
          _buildDropdownField(
            label: 'District',
            value: _selectedDistrict,
            items: _districts,
            icon: Icons.map_outlined,
            onChanged: (v) => setState(() => _selectedDistrict = v ?? ''),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Password ──────────────────────────────────────────────────
  Widget _buildPasswordStep() {
    return SingleChildScrollView(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set Password', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            'Choose a strong password for your account.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 24),
          _buildFormField(
            label: 'Password',
            controller: _passwordController,
            hint: 'Enter a password (min. 8 characters)',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            validator: Validators.validatePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 18),
          _buildFormField(
            label: 'Confirm Password',
            controller: _confirmPasswordController,
            hint: 'Re-enter your password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirm,
            validator: (v) => Validators.validateConfirmPassword(
              v,
              _passwordController.text,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      onChanged: (v) =>
                          setState(() => _agreedToTerms = v ?? false),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'I agree to the ',
                        style: AppTextStyles.caption,
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: AppTextStyles.captionMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: AppTextStyles.captionMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(_errorMessage!),
          ],
        ],
      ),
    );
  }

  // ── Step 4: Google Account Link ────────────────────────────────────────
  Widget _buildGoogleLinkStep() {
    return SingleChildScrollView(
      key: const ValueKey('step4'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text('Account Created!', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            'Your Village Connect account is ready. You can optionally link a Google account for easier sign-in.',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _linkGoogle,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.g_mobiledata, size: 28),
              label: Text(
                'Connect Google Account',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: TextButton(
              onPressed: _isLoading ? null : _skipGoogleLink,
              child: Text(
                'Skip for Now',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(_errorMessage!),
          ],
        ],
      ),
    );
  }

  // ── Error banner ───────────────────────────────────────────────────────
  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared form field builder ─────────────────────────────────────────
  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          obscureText: obscureText,
          validator: validator,
          onChanged: (_) => setState(() {}),
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.surfaceGrey,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
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
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value.isEmpty ? null : value,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
            filled: true,
            fillColor: AppColors.surfaceGrey,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
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
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
          hint: Text(
            'Select $label',
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: AppTextStyles.body),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    // Google link step has inline buttons instead of the bottom bar
    if (_currentStep == 3) return const SizedBox.shrink();

    final isPasswordStep = _currentStep == 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed:
                    (_canProceed && !_isLoading) ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  disabledBackgroundColor: AppColors.disabledBackground,
                  disabledForegroundColor: AppColors.disabled,
                  elevation: _canProceed ? 2 : 0,
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
                    : Text(
                        isPasswordStep ? 'Create Account' : 'Continue',
                        style: AppTextStyles.button,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
