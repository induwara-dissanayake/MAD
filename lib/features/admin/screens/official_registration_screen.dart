import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/admin_user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/credential_email_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/vc_button.dart';
import '../../../shared/widgets/vc_text_field.dart';
import '../controllers/admin_controller.dart';

class OfficialRegistrationScreen extends ConsumerStatefulWidget {
  const OfficialRegistrationScreen({super.key});

  @override
  ConsumerState<OfficialRegistrationScreen> createState() =>
      _OfficialRegistrationScreenState();
}

class _OfficialRegistrationScreenState
    extends ConsumerState<OfficialRegistrationScreen> {
  late final TextEditingController _nicController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _villageController;
  late final TextEditingController _addressController;

  bool _isLoading = false;
  late bool _nicVerified;
  AdminUserModel? _existingUser;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _nicController = TextEditingController();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _villageController = TextEditingController();
    _addressController = TextEditingController();
    _nicVerified = false;
  }

  @override
  void dispose() {
    _nicController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _villageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _verifyNic() async {
    if (_nicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a NIC number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(adminRepositoryProvider);
      final result = await repository
          .nicExists(_nicController.text.trim())
          .run();

      result.fold(
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isLoading = false);
        },
        (exists) {
          if (exists) {
            // Look up existing user
            _lookupExistingUser();
          } else {
            // Clear form for new user entry
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('NIC not found. Please enter full details.'),
              ),
            );
            setState(() {
              _isLoading = false;
              _nicVerified = true;
              _existingUser = null;
            });
          }
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _lookupExistingUser() async {
    try {
      final repository = ref.read(adminRepositoryProvider);
      final result = await repository
          .searchUserByNic(_nicController.text.trim())
          .run();

      result.fold(
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isLoading = false);
        },
        (user) {
          setState(() {
            _existingUser = user;
            _nicVerified = true;
            _isLoading = false;
            _fullNameController.text = user.fullName;
            _phoneController.text = user.phone;
            _emailController.text = user.email;
            _villageController.text = user.village;
            _addressController.text = user.address;
          });
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registerOfficial() async {
    // Validation
    if (_fullNameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _villageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService(FirebaseAuth.instance);
      final credentialEmailService = ref.read(credentialEmailServiceProvider);

      // Generate password
      final tempPassword = AuthService.generatePassword();

      final nic = _nicController.text.trim();
      final authEmail = Validators.nicToEmail(nic);

      // Create account using secondary Firebase app (doesn't drop admin's token)
      final newUid = await authService.createUserAccount(
        email: authEmail,
        password: tempPassword,
      );

      // Add user to Firestore
      await FirebaseFirestore.instance.collection('users').doc(newUid).set({
        'fullName': _fullNameController.text.trim(),
        'fullNameLower': _fullNameController.text.trim().toLowerCase(),
        'nic': nic,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'village': _villageController.text.trim(),
        'district': 'TBD', // Can be filled later
        'role': 'gn_officer',
        'accountStatus': 'pending_first_login',
        'capabilities': {
          'isCommitteeMember': false,
          'canModerateCommunity': true,
          'canManageIncidents': true,
          'canPublishNotices': true,
          'canAccessAdminDashboard': false,
        },
        'memberType': 'new_resident',
        'hasSystemAccess': true,
        'createdByUid':
            ref.read(authServiceProvider).currentUser?.uid ?? 'admin',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      try {
        await credentialEmailService.queueCredentialsEmail(
          toEmail: _emailController.text.trim(),
          fullName: _fullNameController.text.trim(),
          nic: nic,
          password: tempPassword,
          memberTypeLabel: 'GN Officer',
        );
      } catch (_) {
        // The success dialog still exposes credentials so the admin can share
        // them manually if the external email provider is unavailable.
      }

      setState(() {
        _isLoading = false;
      });

      // Show success dialog with password
      if (mounted) {
        _showSuccessDialog(newUid, tempPassword);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String uid, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'GN Officer Registered',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Created Successfully',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCredentialRow('UID', uid),
                    const SizedBox(height: 8),
                    _buildCredentialRow('Username', _nicController.text.trim()),
                    const SizedBox(height: 8),
                    _buildCredentialRow(
                      'Temporary Password',
                      password,
                      isPassword: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Provide the NIC username and temporary password to the GN Officer. They must change their password on first login.',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.warning,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Credentials'),
            onPressed: () {
              _copyCredentialsToClipboard(
                uid,
                _nicController.text.trim(),
                password,
              );
            },
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(
    String label,
    String value, {
    bool isPassword = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.small.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            isPassword && !_showPassword ? '••••••••' : value,
            style: AppTextStyles.small.copyWith(
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _resetForm() {
    setState(() {
      _nicController.clear();
      _fullNameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _villageController.clear();
      _addressController.clear();
      _nicVerified = false;
      _existingUser = null;
      _isLoading = false;
    });
  }

  void _copyCredentialsToClipboard(String uid, String nic, String password) {
    final credentialsText =
        '''GN Officer Account Credentials
━━━━━━━━━━━━━━━━━━━━━━━━━━━
UID: $uid
Username (NIC): $nic
Temporary Password: $password

⚠️  Provide these credentials to the GN Officer.
They must change their password on first login.''';

    Clipboard.setData(ClipboardData(text: credentialsText));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credentials copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go('/admin/dashboard');
          },
        ),
        title: const Text('Register GN Officer'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBox(),
            const SizedBox(height: 24),
            _buildNicVerificationSection(),
            if (_nicVerified) ...[
              const SizedBox(height: 24),
              _buildDetailsSection(),
              const SizedBox(height: 24),
              _buildRegistrationButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_rounded, color: AppColors.info, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Use this form to register new Government Officials. An account will be created with a temporary password.',
              style: AppTextStyles.small.copyWith(
                color: AppColors.info,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNicVerificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Verify NIC',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VcTextField(
                controller: _nicController,
                label: 'NIC Number',
                hint: 'Enter NIC',
                enabled: !_nicVerified,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: VcButton(
                  label: _nicVerified ? 'Change NIC' : 'Verify NIC',
                  onPressed: _isLoading ? null : _verifyNic,
                  isLoading: _isLoading,
                ),
              ),
              if (_existingUser != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'User found: ${_existingUser!.fullName}',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.info,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2: Full Details',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              VcTextField(
                controller: _fullNameController,
                label: 'Full Name',
                hint: 'Enter full name',
                enabled: _existingUser == null,
              ),
              const SizedBox(height: 16),
              VcTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter phone',
                enabled: _existingUser == null,
              ),
              const SizedBox(height: 16),
              VcTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter email',
                enabled: _existingUser == null,
              ),
              const SizedBox(height: 16),
              VcTextField(
                controller: _villageController,
                label: 'Village',
                hint: 'Enter village',
                enabled: _existingUser == null,
              ),
              const SizedBox(height: 16),
              VcTextField(
                controller: _addressController,
                label: 'Address',
                hint: 'Enter address',
                enabled: _existingUser == null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 3: Register',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: VcButton(
            label: 'Register GN Officer',
            onPressed: _isLoading ? null : _registerOfficial,
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }
}
