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
  String _creatorRole = 'citizen';
  bool _isCommitteeMember = false;
  bool _canModerateCommunity = false;
  bool _canAccessAdminDashboard = false;
  String? _errorMessage;
  String? _generatedPassword;
  String? _createdUserName;
  String? _emailDispatchStatus;

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

  Future<void> _loadCreatorRole() async {
    try {
      final uid = ref.read(authServiceProvider).currentUser?.uid;
      if (uid == null) return;
      final profile = await ref
          .read(userServiceProvider)
          .getUserProfileOnce(uid);
      if (!mounted) return;
      final role = profile?.role == 'super_admin' ? 'admin' : profile?.role;
      setState(() {
        _creatorRole = role ?? 'citizen';
      });
    } catch (_) {
      // Keep safe defaults.
    }
  }

  Future<void> _createResident() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final nic = _nicController.text.trim();
      final userService = ref.read(userServiceProvider);
      final authService = ref.read(authServiceProvider);
      final credentialEmailService = ref.read(credentialEmailServiceProvider);
      final currentAdminUid = authService.currentUser?.uid;

      if (currentAdminUid == null) {
        throw Exception('Session expired. Please sign in again.');
      }
      if (await userService.isNicRegistered(nic)) {
        throw Exception('This NIC is already registered.');
      }

      final creatorProfile = await userService.getUserProfileOnce(
        currentAdminUid,
      );
      final creatorRoleRaw = creatorProfile?.role ?? 'citizen';
      final creatorRole = creatorRoleRaw == 'super_admin'
          ? 'admin'
          : creatorRoleRaw;
      if (!['admin_resident', 'gn_officer', 'admin'].contains(creatorRole)) {
        throw Exception('You do not have permission to create accounts.');
      }

      final inheritedVillage = creatorProfile?.village ?? '';
      final inheritedDistrict = creatorProfile?.district ?? '';
      if (inheritedVillage.isEmpty || inheritedDistrict.isEmpty) {
        throw Exception(
          'Your profile needs village and district before registration.',
        );
      }

      final password = AuthService.generatePassword();
      final authEmail = Validators.nicToEmail(nic);
      final newUid = await authService.createUserAccount(
        email: authEmail,
        password: password,
      );

      final role = _allowedRoleForCreator(creatorRole);
      final capabilities = {
        'isCommitteeMember': _isCommitteeMember,
        'canModerateCommunity': _canModerateCommunity || _isCommitteeMember,
        'canAccessAdminDashboard':
            creatorRole == 'admin' && _canAccessAdminDashboard,
      };

      final userModel = UserModel(
        uid: newUid,
        fullName: _fullNameController.text.trim(),
        nic: nic,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        village: inheritedVillage,
        district: inheritedDistrict,
        role: role,
        accountStatus: 'pending_first_login',
        capabilities: capabilities,
        memberType: MemberType.newResident,
        createdByUid: currentAdminUid,
        createdAt: DateTime.now(),
      );

      await userService.createUserProfile(userModel);

      try {
        await credentialEmailService.queueCredentialsEmail(
          toEmail: _emailController.text.trim(),
          fullName: _fullNameController.text.trim(),
          nic: nic,
          password: password,
          memberTypeLabel: MemberType.newResident.label,
        );
        _emailDispatchStatus =
            'Login credentials were emailed to ${_emailController.text.trim()}.';
      } catch (error) {
        _emailDispatchStatus =
            'Account created, but email delivery failed. Share credentials securely.';
      }

      if (!mounted) return;
      setState(() {
        _isDone = true;
        _isLoading = false;
        _generatedPassword = password;
        _createdUserName = _fullNameController.text.trim();
      });
    } on FirebaseAuthException catch (error) {
      _setError(_mapAuthError(error.code));
    } catch (error) {
      _setError(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  String _allowedRoleForCreator(String creatorRole) {
    return 'citizen';
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This NIC already has a login account.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled in Firebase.';
      default:
        return 'Registration failed ($code).';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _creatorRole == 'admin';
    return Scaffold(
      backgroundColor: AppColors.surfaceParchment,
      appBar: AppBar(
        title: const Text('Register Citizen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _handleBack,
        ),
      ),
      body: _isDone ? _buildSuccessView() : _buildForm(isAdmin: isAdmin),
    );
  }

  Widget _buildForm({required bool isAdmin}) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _RegistrationHero(isAdmin: isAdmin),
          const SizedBox(height: 20),
          const _StepLabel(number: '1', label: 'Citizen Details'),
          const SizedBox(height: 12),
          _FormPanel(
            children: [
              _Field(
                label: 'Full name',
                controller: _fullNameController,
                hint: 'Name as used for GN records',
                icon: Icons.person_outline,
                validator: Validators.validateFullName,
              ),
              _Field(
                label: 'NIC number',
                controller: _nicController,
                hint: '200012345678 or 987654321V',
                icon: Icons.badge_outlined,
                validator: Validators.validateNic,
              ),
              _Field(
                label: 'Phone number',
                controller: _phoneController,
                hint: '077 123 4567',
                icon: Icons.call_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
              ),
              _Field(
                label: 'Email for credentials',
                controller: _emailController,
                hint: 'citizen@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              _Field(
                label: 'Home address',
                controller: _addressController,
                hint: 'Permanent address',
                icon: Icons.location_on_outlined,
                maxLines: 2,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Address is required'
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _StepLabel(number: '2', label: 'Access'),
          const SizedBox(height: 12),
          _FormPanel(
            children: [
              _AccessNote(isAdmin: isAdmin),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Committee member',
                  style: AppTextStyles.bodySemiBold,
                ),
                subtitle: Text(
                  'Use for village committee support without changing the citizen role.',
                  style: AppTextStyles.caption,
                ),
                value: _isCommitteeMember,
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() {
                        _isCommitteeMember = value;
                        if (value) _canModerateCommunity = true;
                      }),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Can moderate community',
                  style: AppTextStyles.bodySemiBold,
                ),
                subtitle: Text(
                  'Allows approving or removing community posts.',
                  style: AppTextStyles.caption,
                ),
                value: _canModerateCommunity || _isCommitteeMember,
                onChanged: _isLoading || _isCommitteeMember
                    ? null
                    : (value) => setState(() => _canModerateCommunity = value),
              ),
              if (isAdmin)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Admin dashboard access',
                    style: AppTextStyles.bodySemiBold,
                  ),
                  subtitle: Text(
                    'Allows opening /admin screens.',
                    style: AppTextStyles.caption,
                  ),
                  value: _canAccessAdminDashboard,
                  onChanged: _isLoading
                      ? null
                      : (value) =>
                            setState(() => _canAccessAdminDashboard = value),
                ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _MessageBox(message: _errorMessage!, isError: true),
          ],
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _isLoading ? null : _createResident,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_alt_outlined),
            label: Text(_isLoading ? 'Creating account...' : 'Create Account'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final nic = _nicController.text.trim();
    final password = _generatedPassword ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 72,
        ),
        const SizedBox(height: 16),
        Text(
          'Account Created',
          textAlign: TextAlign.center,
          style: AppTextStyles.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          '${_createdUserName ?? 'Citizen'} is now pending first login.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: AppColors.inkMid),
        ),
        const SizedBox(height: 22),
        _FormPanel(
          children: [
            Text('Temporary Credentials', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            _CredentialRow(label: 'Username', value: nic),
            _CredentialRow(label: 'Password', value: password),
            const SizedBox(height: 8),
            _MessageBox(message: _emailDispatchStatus ?? '', isError: false),
          ],
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(
              ClipboardData(text: 'NIC: $nic\nPassword: $password'),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Credentials copied.')),
            );
          },
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Copy Credentials'),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: _handleBack,
          child: Text(
            _creatorRole == 'admin'
                ? 'Back to Admin Dashboard'
                : _creatorRole == 'gn_officer'
                ? 'Back to GN Dashboard'
                : 'Back to Home',
          ),
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required to send credentials';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(text)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    if (_creatorRole == 'admin') {
      context.go('/admin/dashboard');
    } else if (_creatorRole == 'gn_officer') {
      context.go('/official/dashboard');
    } else {
      context.go('/home');
    }
  }
}

class _RegistrationHero extends StatelessWidget {
  const _RegistrationHero({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Register Citizen',
            style: AppTextStyles.displaySmall.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            isAdmin
                ? 'Create a citizen account, set Firestore capabilities, and send temporary credentials.'
                : 'Create a citizen account with first-login setup and email credentials.',
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.brandGreen,
          foregroundColor: Colors.white,
          child: Text(
            number,
            style: AppTextStyles.small.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Text(label.toUpperCase(), style: AppTextStyles.overline),
      ],
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceIvory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceWarmSand),
        boxShadow: AppColors.shadowLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}

class _AccessNote extends StatelessWidget {
  const _AccessNote({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return _MessageBox(
      message: isAdmin
          ? 'This route creates citizen profiles. Use Register GN Officer for GN accounts.'
          : 'GN officers create citizen accounts. Committee access can be enabled below.',
      isError: false,
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 96, child: Text(label, style: AppTextStyles.caption)),
        Expanded(child: Text(value, style: AppTextStyles.monoMedium)),
      ],
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorLight : AppColors.brandGreenSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? AppColors.errorRed : AppColors.brandGreenBorder,
        ),
      ),
      child: Text(
        message,
        style: AppTextStyles.caption.copyWith(
          color: isError ? AppColors.errorRed : AppColors.brandGreen,
        ),
      ),
    );
  }
}
