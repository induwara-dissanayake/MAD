import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/vc_components.dart';

class FirstLoginSetupScreen extends ConsumerStatefulWidget {
  const FirstLoginSetupScreen({super.key});

  @override
  ConsumerState<FirstLoginSetupScreen> createState() =>
      _FirstLoginSetupScreenState();
}

class _FirstLoginSetupScreenState extends ConsumerState<FirstLoginSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loadedProfile = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (_loadedProfile) return;
    _loadedProfile = true;
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return;
    final profile = await ref.read(userServiceProvider).getUserProfileOnce(uid);
    if (!mounted || profile == null) return;
    _fullNameController.text = profile.fullName;
    _phoneController.text = profile.phone;
    _addressController.text = profile.address;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) {
      context.go(RoutePaths.login);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authServiceProvider)
          .changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      await ref
          .read(userServiceProvider)
          .completeFirstLoginProfile(
            uid: uid,
            fullName: _fullNameController.text,
            phone: _phoneController.text,
            address: _addressController.text,
          );
      await ref
          .read(authServiceProvider)
          .updateDisplayName(_fullNameController.text.trim());

      if (!mounted) return;
      final destination = await _dashboardFor(uid);
      if (mounted) context.go(destination);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(e.message ?? 'Unable to activate account.');
    } catch (e) {
      if (!mounted) return;
      _showError('Unable to activate account. ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<String> _dashboardFor(String uid) async {
    final profile = await ref.read(userServiceProvider).getUserProfileOnce(uid);
    final role = profile?.role == 'super_admin' ? 'admin' : profile?.role;
    final caps = profile?.capabilities ?? const <String, bool>{};
    if (role == 'admin' || caps['canAccessAdminDashboard'] == true) {
      return RoutePaths.adminDashboard;
    }
    if (role == 'gn_officer') return RoutePaths.officialDashboard;
    if (role == 'committee') {
      return RoutePaths.committeeTasks;
    }
    return RoutePaths.home;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _loadProfile();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activate Account'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VcPageHeader(
                title: 'Secure your account',
                subtitle:
                    'Change the temporary password and confirm your profile before dashboard access.',
                leadingIcon: Icons.verified_user_rounded,
              ),
              const SizedBox(height: 24),
              Text('Security', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              _passwordField(
                controller: _currentPasswordController,
                label: 'Temporary Password',
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (v) => v == null || v.isEmpty
                    ? 'Temporary password is required'
                    : null,
              ),
              const SizedBox(height: 16),
              _passwordField(
                controller: _newPasswordController,
                label: 'New Password',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 16),
              _passwordField(
                controller: _confirmPasswordController,
                label: 'Confirm New Password',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) => Validators.validateConfirmPassword(
                  v,
                  _newPasswordController.text,
                ),
              ),
              const SizedBox(height: 28),
              Text('Profile', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              _textField(
                controller: _fullNameController,
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                validator: Validators.validateFullName,
              ),
              const SizedBox(height: 16),
              _textField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
              ),
              const SizedBox(height: 16),
              _textField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on_outlined,
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Address is required'
                    : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    _isSubmitting ? 'Activating...' : 'Activate Account',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return _textField(
      controller: controller,
      label: label,
      icon: Icons.lock_outline_rounded,
      obscureText: obscure,
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility),
      ),
      validator: validator,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
