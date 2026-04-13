import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/credential_email_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';

/// Screen for admin-residents to register a brand-new village resident.
/// The new resident receives their login credentials via email.
class CreateResidentScreen extends ConsumerStatefulWidget {
  const CreateResidentScreen({super.key});

  @override
  ConsumerState<CreateResidentScreen> createState() =>
      _CreateResidentScreenState();
}

class _CreateResidentScreenState extends ConsumerState<CreateResidentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _nicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isDone = false;
  String? _errorMessage;
  String? _generatedPassword;
  String? _createdUserName;
  String? _emailDispatchStatus;
  String _creatorRole = 'citizen';
  String _targetRole = 'citizen';

  @override
  void initState() {
    super.initState();
    _loadCreatorRole();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nicController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _loadCreatorRole() async {
    try {
      final authService = ref.read(authServiceProvider);
      final userService = ref.read(userServiceProvider);
      final uid = authService.currentUser?.uid;
      if (uid == null) return;

      final profile = await userService.getUserProfileOnce(uid);
      if (!mounted) return;

      final role = profile?.role ?? 'citizen';
      final normalizedRole = role == 'super_admin' ? 'admin' : role;
      setState(() {
        _creatorRole = normalizedRole;
        if (_creatorRole != 'gn_officer' && _creatorRole != 'admin') {
          _targetRole = 'citizen';
        }
      });
    } catch (_) {
      // Keep safe defaults.
    }
  }

  Future<void> _createResident() async {
    if (!_formKey.currentState!.validate()) return;

    _safeSetState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final nic = _nicController.text.trim();
      final userService = ref.read(userServiceProvider);
      final authService = ref.read(authServiceProvider);
      final credentialEmailService = ref.read(credentialEmailServiceProvider);

      // Check NIC uniqueness
      final alreadyExists = await userService.isNicRegistered(nic);
      if (alreadyExists) {
        _safeSetState(() {
          _isLoading = false;
          _errorMessage = 'This NIC is already registered in the system.';
        });
        return;
      }

      // Generate credentials
      final password = AuthService.generatePassword();
      final email = Validators.nicToEmail(nic);
      final currentAdminUid = authService.currentUser?.uid;

      if (currentAdminUid == null) {
        throw Exception('Session expired. Please sign in again.');
      }

      final creatorProfile = await userService.getUserProfileOnce(
        currentAdminUid,
      );
      final creatorRoleRaw = creatorProfile?.role ?? 'citizen';
      final creatorRole =
          creatorRoleRaw == 'super_admin' ? 'admin' : creatorRoleRaw;
      if (creatorRole != 'admin_resident' &&
          creatorRole != 'gn_officer' &&
          creatorRole != 'admin') {
        throw Exception(
          'You do not have permission to create new resident records.',
        );
      }
      if (_targetRole == 'admin_resident' &&
          creatorRole != 'gn_officer' &&
          creatorRole != 'admin') {
        throw Exception('Only GN Officer can create resident admin accounts.');
      }

      final inheritedVillage = creatorProfile?.village ?? '';
      final inheritedDistrict = creatorProfile?.district ?? '';

      if (inheritedVillage.isEmpty || inheritedDistrict.isEmpty) {
        throw Exception(
          'Your profile is missing village/district. Update your profile before creating residents.',
        );
      }

      // Create Firebase Auth account for the new resident without signing out
      // the current admin session (handled in AuthService via secondary app).
      final newUid = await authService.createUserAccount(
        email: email,
        password: password,
      );

      // Create Firestore profile for the new resident
      final userModel = UserModel(
        uid: newUid,
        fullName: _fullNameController.text.trim(),
        nic: nic,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        village: inheritedVillage,
        district: inheritedDistrict,
        role: _targetRole,
        memberType: MemberType.newResident,
        createdByUid: currentAdminUid,
        createdAt: DateTime.now(),
      );

      await userService.createUserProfile(userModel);

      String emailStatus;
      try {
        await credentialEmailService.queueCredentialsEmail(
          toEmail: _emailController.text.trim(),
          fullName: _fullNameController.text.trim(),
          nic: nic,
          password: password,
          memberTypeLabel: MemberType.newResident.label,
        );
        emailStatus =
            '✅ Login credentials were sent to ${_emailController.text.trim()}.';
      } catch (e) {
        emailStatus =
            '⚠️ Account was created, but automatic email delivery failed (${e.toString()}). Please share the credentials manually.';
      }

      _safeSetState(() {
        _isLoading = false;
        _isDone = true;
        _generatedPassword = password;
        _createdUserName = _fullNameController.text.trim();
        _emailDispatchStatus = emailStatus;
      });
    } on FirebaseAuthException catch (e) {
      _safeSetState(() {
        _isLoading = false;
        _errorMessage = _mapAuthError(e.code);
      });
    } catch (e) {
      _safeSetState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to create resident. Please try again.\n${e.toString()}';
      });
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This NIC is already registered. Please verify the NIC number.';
      case 'weak-password':
        return 'Internal error: generated password too weak.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled. Contact the system administrator.';
      default:
        return 'Registration failed ($code). Please try again.';
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
          onPressed: () => context.pop(),
        ),
        title: Text(
          _creatorRole == 'gn_officer'
              ? 'Register Citizen'
              : _creatorRole == 'admin'
                  ? 'Create User'
                  : 'Register New Resident',
          style: AppTextStyles.h3,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_creatorRole == 'gn_officer') _buildGnOfficerHeader(),
          if (_creatorRole == 'admin')
            _buildAdminHeader(),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(child: _isDone ? _buildSuccessView() : _buildForm()),
        ],
      ),
    );
  }

  Widget _buildAdminHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Admin management access',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Use this form to create citizens, resident admins, or committee accounts. Login credentials will be generated automatically.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGnOfficerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Register New Citizen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'GN Division 521 — Kaduwela',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Enter the citizen\'s NIC number. The system will generate their login credentials automatically.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(),
            const SizedBox(height: 24),
            Text('Resident Details', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text(
              'Fill in the details provided by the new resident.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 24),

            _buildFormField(
              label: 'Full Name',
              controller: _fullNameController,
              hint: 'Enter resident\'s full name',
              icon: Icons.person_outline_rounded,
              validator: Validators.validateFullName,
            ),
            const SizedBox(height: 18),
            _buildFormField(
              label: 'NIC Number',
              controller: _nicController,
              hint: 'e.g., 200012345678 or 987654321V',
              icon: Icons.badge_outlined,
              validator: Validators.validateNic,
            ),
            const SizedBox(height: 18),
            _buildFormField(
              label: 'Contact Number',
              controller: _phoneController,
              hint: '077 123 4567',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhone,
            ),
            const SizedBox(height: 18),
            _buildFormField(
              label: 'Email Address',
              controller: _emailController,
              hint: 'resident@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Email is required to send login credentials';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            if (_creatorRole == 'gn_officer' ||
                _creatorRole == 'admin') ...[
              const SizedBox(height: 18),
              Text('Account Role', style: AppTextStyles.label),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _targetRole,
                items: (_creatorRole == 'admin'
                        ? const [
                            DropdownMenuItem(
                              value: 'citizen',
                              child: Text('Citizen'),
                            ),
                            DropdownMenuItem(
                              value: 'admin_resident',
                              child: Text('Resident Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'committee',
                              child: Text('Committee'),
                            ),
                          ]
                        : const [
                            DropdownMenuItem(
                              value: 'citizen',
                              child: Text('Citizen'),
                            ),
                            DropdownMenuItem(
                              value: 'admin_resident',
                              child: Text('Resident Admin'),
                            ),
                          ])
                    .toList(),
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _targetRole = value);
                      },
                decoration: InputDecoration(
                  hintText: 'Select role for the new account',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            _buildFormField(
              label: 'Home Address',
              controller: _addressController,
              hint: 'Enter permanent address',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              _buildErrorBanner(_errorMessage!),
            ],

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createResident,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  elevation: 2,
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
                        'Create Resident Account',
                        style: AppTextStyles.button,
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final nic = _nicController.text.trim();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          Text('Resident Registered!', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            '$_createdUserName has been successfully registered.',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.key_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Login Credentials',
                      style: AppTextStyles.bodySemiBold.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: AppColors.border),
                _credentialRow('Username (NIC)', nic),
                const SizedBox(height: 12),
                _credentialRow('Temporary Password', _generatedPassword ?? ''),
                const SizedBox(height: 16),
                Text(
                  _emailDispatchStatus ??
                      'ℹ️ Share these credentials with the resident securely.',
                  style: AppTextStyles.small.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildCopyButton(nic, _generatedPassword ?? ''),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You are still signed in. You can continue creating accounts or return home.',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Back to Home', style: AppTextStyles.button),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _credentialRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyButton(String nic, String password) {
    return OutlinedButton.icon(
      onPressed: () {
        Clipboard.setData(
          ClipboardData(text: 'NIC: $nic\nPassword: $password'),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credentials copied to clipboard')),
        );
      },
      icon: const Icon(Icons.copy_rounded, size: 18),
      label: const Text('Copy Credentials'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.admin_panel_settings_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You are creating a NEW RESIDENT account. '
              'Login credentials will be emailed to the resident automatically.',
              style: AppTextStyles.small.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
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
          validator: validator,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
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
}
