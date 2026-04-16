import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/credential_email_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';

class EditFamilyMemberScreen extends ConsumerStatefulWidget {
  final String memberUid;

  const EditFamilyMemberScreen({super.key, required this.memberUid});

  @override
  ConsumerState<EditFamilyMemberScreen> createState() =>
      _EditFamilyMemberScreenState();
}

class _EditFamilyMemberScreenState
    extends ConsumerState<EditFamilyMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _nicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  static const List<String> _relationships = [
    'Spouse',
    'Child',
    'Parent',
    'Sibling',
    'Grandparent',
    'Guardian',
    'Other',
  ];

  String? _selectedRelationship;
  bool _hasSystemAccess = false;
  bool _originalSystemAccess = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isDone = false;
  String? _generatedPassword;
  String? _emailDispatchStatus;

  // ── Design tokens ─────────────────────────────────────────────────────
  static const _bg = Color(0xFFF9F9F9);
  static const _surface = Color(0xFFFFFFFF);
  static const _primary = Color(0xFF0d631b);
  static const _primaryContainer = Color(0xFF2e7d32);
  static const _ink = Color(0xFF1A1C1C);
  static const _divider = Color(0xFFBFCABA);

  @override
  void initState() {
    super.initState();
    _loadMember();
  }

  Future<void> _loadMember() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberUid)
          .get();
      if (!mounted) return;
      final data = doc.data();
      if (data != null) {
        _fullNameController.text = data['fullName'] as String? ?? '';
        _nicController.text = data['nic'] as String? ?? '';
        _phoneController.text = data['phone'] as String? ?? '';
        _emailController.text = data['email'] as String? ?? '';
        final relationship = data['relationship'] as String?;
        if (relationship != null && _relationships.contains(relationship)) {
          _selectedRelationship = relationship;
        }
        _hasSystemAccess = data['hasSystemAccess'] as bool? ?? false;
        _originalSystemAccess = _hasSystemAccess;
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nicController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      if (_hasSystemAccess && !_originalSystemAccess) {
        final nic = _nicController.text.trim();
        final email = _emailController.text.trim();
        final authService = ref.read(authServiceProvider);
        final credentialEmailService = ref.read(credentialEmailServiceProvider);
        final userService = ref.read(userServiceProvider);

        final alreadyExists = await userService.isNicRegistered(nic);
        if (alreadyExists) {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.memberUid)
              .get();
          final existingNic = doc.data()?['nic'] as String? ?? '';
          if (existingNic != nic) {
            if (!mounted) return;
            _showSnack(
              'This NIC is already registered in the system.',
              isError: true,
            );
            setState(() => _isSubmitting = false);
            return;
          }
        }

        final password = AuthService.generatePassword();
        final authEmail = Validators.nicToEmail(nic);
        await authService.createUserAccount(
          email: authEmail,
          password: password,
        );

        String emailStatus;
        try {
          await credentialEmailService.queueCredentialsEmail(
            toEmail: email,
            fullName: _fullNameController.text.trim(),
            nic: nic,
            password: password,
            memberTypeLabel: 'Family Member',
          );
          emailStatus = '✅ Login credentials were sent to $email.';
        } catch (e) {
          emailStatus =
              '⚠️ Account created, but email delivery failed. Share credentials manually.';
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.memberUid)
            .update({
              'fullName': _fullNameController.text.trim(),
              'nic': nic,
              'phone': _phoneController.text.trim(),
              'email': email,
              'relationship': _selectedRelationship ?? '',
              'hasSystemAccess': true,
            });

        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _isDone = true;
          _generatedPassword = password;
          _emailDispatchStatus = emailStatus;
        });
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberUid)
          .update({
            'fullName': _fullNameController.text.trim(),
            'nic': _nicController.text.trim(),
            'phone': _phoneController.text.trim(),
            'email': _emailController.text.trim(),
            'relationship': _selectedRelationship ?? '',
            'hasSystemAccess': _hasSystemAccess,
          });

      if (!mounted) return;
      _showSnack('Family member updated successfully.');
      context.pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showSnack(_mapAuthError(e.code), isError: true);
    } catch (e) {
      print('Update error: $e');
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
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

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This NIC is already registered. Please verify the NIC number.';
      case 'weak-password':
        return 'Internal error: generated password too weak.';
      default:
        return 'Registration failed ($code). Please try again.';
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Member',
          style: TextStyle(
            fontFamily: 'PublicSans',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: _ink,
          ),
        ),
        content: Text(
          'This will permanently remove this family member from your household.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: _ink.withOpacity(0.6),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _ink.withOpacity(0.4),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Remove',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isSubmitting = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberUid)
          .delete();
      if (!mounted) return;
      _showSnack('Family member removed.');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to remove. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
          'Edit Member',
          style: TextStyle(
            fontFamily: 'PublicSans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.36,
            color: _ink,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isDone)
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error.withOpacity(0.8),
              ),
              onPressed: _isSubmitting ? null : _confirmDelete,
              tooltip: 'Remove member',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _divider.withOpacity(0.15)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _isDone
          ? _buildSuccessView()
          : _buildForm(),
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
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
                      Icons.edit_outlined,
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
                          'Update Details',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Changes will be saved to the household registry.',
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

            _buildSectionLabel('Identity'),
            const SizedBox(height: 14),
            _buildTextField(
              label: 'Full Name',
              controller: _fullNameController,
              icon: Icons.person_outline_rounded,
              keyboardType: TextInputType.name,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Full name is required'
                  : null,
            ),
            const SizedBox(height: 14),
            _buildRelationshipField(),
            const SizedBox(height: 14),
            _buildTextField(
              label: 'NIC',
              controller: _nicController,
              icon: Icons.badge_outlined,
              validator: (v) {
                if (_hasSystemAccess && !_originalSystemAccess) {
                  return Validators.validateNic(v);
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            _buildSectionLabel('Contact'),
            const SizedBox(height: 14),
            _buildTextField(
              label: 'Phone Number',
              controller: _phoneController,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Phone number is required';
                if (!RegExp(r'^\+?[\d\s\-]{7,15}$').hasMatch(v.trim())) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildTextField(
              label: 'Email Address',
              controller: _emailController,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (_hasSystemAccess && !_originalSystemAccess) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email is required to send credentials';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                    return 'Enter a valid email address';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            _buildSectionLabel('Access'),
            const SizedBox(height: 14),
            _buildToggleTile(),

            if (_hasSystemAccess && !_originalSystemAccess) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: _primary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'NIC and Email are required to generate login credentials. Credentials will be sent to the provided email.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: _primary.withOpacity(0.85),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────
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

  // ── Save Button ───────────────────────────────────────────────────────
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
                  'Save Changes',
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

  // ── Toggle Tile ───────────────────────────────────────────────────────
  Widget _buildToggleTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.05),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _hasSystemAccess
                  ? _primary.withOpacity(0.1)
                  : _ink.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _hasSystemAccess
                  ? Icons.lock_open_rounded
                  : Icons.lock_outline_rounded,
              size: 18,
              color: _hasSystemAccess ? _primary : _ink.withOpacity(0.3),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Access',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _originalSystemAccess
                      ? 'This member already has system access.'
                      : 'Enable to create login credentials.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: _ink.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _hasSystemAccess,
            onChanged: _originalSystemAccess
                ? null
                : (v) => setState(() => _hasSystemAccess = v),
            activeColor: _primary,
          ),
        ],
      ),
    );
  }

  // ── Text Field ────────────────────────────────────────────────────────
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
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
          validator: validator,
          keyboardType: keyboardType,
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
              child: Icon(icon, size: 18, color: _primary),
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

  // ── Relationship Dropdown ─────────────────────────────────────────────
  Widget _buildRelationshipField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relationship',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _ink.withOpacity(0.5),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedRelationship,
          onChanged: (v) => setState(() => _selectedRelationship = v),
          validator: (v) =>
              v == null || v.isEmpty ? 'Please select relationship' : null,
          dropdownColor: _surface,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: _ink,
          ),
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.family_restroom_rounded,
                size: 18,
                color: _primary,
              ),
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
          hint: Text(
            'Select relationship',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: _ink.withOpacity(0.3),
            ),
          ),
          items: _relationships
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: _ink,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // ── Success View ──────────────────────────────────────────────────────
  Widget _buildSuccessView() {
    final nic = _nicController.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
      child: Column(
        children: [
          // Success icon
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primary, _primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Access Granted',
            style: TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.56,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_fullNameController.text.trim()} can now log in to the app.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: _ink.withOpacity(0.5),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Credentials card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _ink.withOpacity(0.05),
                  blurRadius: 32,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.key_rounded,
                        color: _primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Login Credentials',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: _divider.withOpacity(0.15)),
                const SizedBox(height: 16),
                _credentialRow('Username (NIC)', nic),
                const SizedBox(height: 14),
                _credentialRow('Temporary Password', _generatedPassword ?? ''),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _emailDispatchStatus ?? '',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: _primary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Copy button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(
                    text: 'NIC: $nic\nPassword: ${_generatedPassword ?? ''}',
                  ),
                );
                _showSnack('Credentials copied to clipboard.');
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text(
                'Copy Credentials',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: BorderSide(color: _primary.withOpacity(0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Back button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primary, _primaryContainer],
                ),
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
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Back to Profile',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _credentialRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: _ink.withOpacity(0.45),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ),
      ],
    );
  }
}
