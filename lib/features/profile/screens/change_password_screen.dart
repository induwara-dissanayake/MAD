import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:village_connect/core/utils/validators.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  // ── Design tokens (matching ChangePersonalInfoScreen) ─────────────────
  static const _bg = Color(0xFFF9F9F9);
  static const _surface = Color(0xFFFFFFFF);
  static const _primary = Color(0xFF0d631b);
  static const _primaryContainer = Color(0xFF2e7d32);
  static const _ink = Color(0xFF1A1C1C);
  static const _divider = Color(0xFFBFCABA);

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authServiceProvider)
          .changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );

      if (!mounted) return;
      _showSnack('Password changed successfully.');
      context.pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Current password is incorrect.';
          break;
        case 'weak-password':
          message = 'New password is too weak.';
          break;
        case 'requires-recent-login':
          message = 'Please sign in again before changing your password.';
          break;
        case 'missing-email':
          message = 'Unable to verify account email for password change.';
          break;
        default:
          message = e.message ?? 'Failed to change password.';
      }
      _showSnack(message, isError: true);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Failed to change password. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontFamily: 'PublicSans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.36,
            color: _ink,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _divider.withOpacity(0.15)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: _primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Secure Password Update',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Create a strong password to protect your account.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: _ink.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _buildSectionLabel('Current Password'),
              const SizedBox(height: 14),
              _buildPasswordField(
                label: 'Current Password',
                controller: _currentPasswordController,
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (value) => value == null || value.isEmpty
                    ? 'Current password is required'
                    : null,
              ),
              const SizedBox(height: 28),

              _buildSectionLabel('New Password'),
              const SizedBox(height: 14),
              _buildPasswordField(
                label: 'New Password',
                controller: _newPasswordController,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: (value) {
                  final base = Validators.validatePassword(
                    value,
                  ); // Keep your validator
                  if (base != null) return base;
                  if (value == _currentPasswordController.text) {
                    return 'New password must be different from current';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              _buildSectionLabel('Confirm New Password'),
              const SizedBox(height: 14),
              _buildPasswordField(
                label: 'Confirm New Password',
                controller: _confirmPasswordController,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (value) => Validators.validateConfirmPassword(
                  value,
                  _newPasswordController.text,
                ),
              ),

              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Label (same as personal info screen) ───────────────────────
  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: _primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(height: 1, color: _primary.withOpacity(0.12)),
        ),
      ],
    );
  }

  // ── Save Button (gradient style) ───────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_primary, _primaryContainer]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Update Password',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Password Field (styled to match personal info text fields) ─────────
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _ink.withOpacity(0.5),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: _ink,
          ),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: _ink.withOpacity(0.3),
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: _primary,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _ink.withOpacity(0.35),
                size: 20,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: _surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _divider.withOpacity(0.15),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _divider.withOpacity(0.15),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.error.withOpacity(0.5),
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
