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

/// Screen for any registered resident to add a family member or rental user.
/// The new member receives login credentials via email.
class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _nicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  MemberType _selectedType = MemberType.familyMember;
  String _selectedVillage = '';
  String _selectedDistrict = '';

  bool _isLoading = false;
  bool _isDone = false;
  String? _errorMessage;
  String? _generatedPassword;
  String? _createdUserName;
  MemberType? _createdMemberType;
  String? _emailDispatchStatus;

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
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVillage.isEmpty || _selectedDistrict.isEmpty) {
      setState(() => _errorMessage = 'Please select village and district.');
      return;
    }

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
      final currentUserUid = authService.currentUser?.uid;

      // Create Firebase Auth account
      final newUid = await authService.createUserAccount(
        email: email,
        password: password,
      );

      // Create Firestore user profile
      final userModel = UserModel(
        uid: newUid,
        fullName: _fullNameController.text.trim(),
        nic: nic,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        village: _selectedVillage,
        district: _selectedDistrict,
        role: 'citizen',
        memberType: _selectedType,
        createdByUid: currentUserUid,
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
          memberTypeLabel: _selectedType.label,
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
        _createdMemberType = _selectedType;
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
            'Failed to add member. Please try again.\n${e.toString()}';
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
        return 'Email/Password sign-in is not enabled. Contact your administrator.';
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
        title: Text('Add Member', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: AppColors.divider),
          Expanded(child: _isDone ? _buildSuccessView() : _buildForm()),
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
            // Member type selector
            Text('Member Type', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text(
              'Select how this person is associated with your household.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),
            _buildMemberTypeSelector(),
            const SizedBox(height: 28),

            Text('Personal Details', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text(
              'Fill in the details provided by the new member.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 24),

            _buildFormField(
              label: 'Full Name',
              controller: _fullNameController,
              hint: 'Enter full name',
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
              hint: '+94 77 123 4567',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhone,
            ),
            const SizedBox(height: 18),
            _buildFormField(
              label: 'Email Address',
              controller: _emailController,
              hint: 'member@example.com',
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
            const SizedBox(height: 18),
            _buildFormField(
              label: 'Address',
              controller: _addressController,
              hint: 'Enter address',
              icon: Icons.location_on_outlined,
              maxLines: 2,
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

            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              _buildErrorBanner(_errorMessage!),
            ],

            const SizedBox(height: 20),
            _buildWarningBox(),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addMember,
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
                        'Add ${_selectedType.label}',
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

  Widget _buildMemberTypeSelector() {
    return Row(
      children: [
        _typeChip(
          MemberType.familyMember,
          Icons.family_restroom_rounded,
          'Family Member',
          AppColors.primary,
          AppColors.primaryLight,
        ),
        const SizedBox(width: 12),
        _typeChip(
          MemberType.rental,
          Icons.house_siding_rounded,
          'Rental',
          const Color(0xFF6A1B9A),
          const Color(0xFFF3E5F5),
        ),
      ],
    );
  }

  Widget _typeChip(
    MemberType type,
    IconData icon,
    String label,
    Color activeColor,
    Color activeBg,
  ) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : AppColors.surfaceGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : AppColors.textMuted,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.captionMedium.copyWith(
                  color: isSelected ? activeColor : AppColors.textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final nic = _nicController.text.trim();
    final typeLabel = _createdMemberType?.label ?? 'Member';
    final typeColor = _createdMemberType == MemberType.rental
        ? const Color(0xFF6A1B9A)
        : AppColors.primary;

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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              typeLabel,
              style: AppTextStyles.captionMedium.copyWith(
                color: typeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Member Added!', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            '$_createdUserName has been registered as a $typeLabel.',
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
                      'ℹ️ Share these credentials with the member securely.',
                  style: AppTextStyles.small.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(
                  text: 'NIC: $nic\nPassword: ${_generatedPassword ?? ''}',
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Credentials copied to clipboard'),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy Credentials'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

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
                    'You are still signed in. You can continue adding members or return home.',
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

  Widget _buildWarningBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ℹ️ The account will be created without signing you out. '
              'Credentials are shown here and sent via email automatically.',
              style: AppTextStyles.small.copyWith(color: AppColors.warning),
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
}
