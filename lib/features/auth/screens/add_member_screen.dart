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
  String? _relationship;

  bool _createSystemAccess = true;
  bool _useSameAddress = true;

  bool _isLoading = false;
  bool _isDone = false;
  bool _isLoadingProfile = true;
  bool _createdWithSystemAccess = false;
  String? _errorMessage;
  String? _generatedPassword;
  String? _createdUserName;
  MemberType? _createdMemberType;
  String? _emailDispatchStatus;

  UserModel? _creatorProfile;

  static const List<String> _relationships = [
    'Spouse',
    'Child',
    'Parent',
    'Sibling',
    'Grandparent',
    'Guardian',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadCreatorProfile();
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

  Future<void> _loadCreatorProfile() async {
    try {
      final authService = ref.read(authServiceProvider);
      final userService = ref.read(userServiceProvider);
      final uid = authService.currentUser?.uid;

      if (uid == null) {
        _safeSetState(() {
          _isLoadingProfile = false;
          _errorMessage = 'Session expired. Please sign in again.';
        });
        return;
      }

      final creator = await userService.getUserProfileOnce(uid);
      _safeSetState(() {
        _creatorProfile = creator;
        _isLoadingProfile = false;
        if (_useSameAddress) {
          _addressController.text = creator?.address ?? '';
        }
      });
    } catch (_) {
      _safeSetState(() {
        _isLoadingProfile = false;
        _errorMessage = 'Failed to load your profile details.';
      });
    }
  }

  Future<void> _addMember() async {
    if (_selectedType == MemberType.familyMember &&
        (_relationship == null || _relationship!.isEmpty)) {
      setState(
        () => _errorMessage = 'Please select relationship for family member.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    _safeSetState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final authService = ref.read(authServiceProvider);
      final credentialEmailService = ref.read(credentialEmailServiceProvider);
      final currentUserUid = authService.currentUser?.uid;

      if (currentUserUid == null) {
        throw Exception('Session expired. Please sign in again.');
      }

      final creator =
          _creatorProfile ??
          await userService.getUserProfileOnce(currentUserUid);
      if (creator == null) {
        throw Exception('Your profile is not available.');
      }

      final creatorRole = creator.role;
      if (creatorRole != 'citizen' &&
          creatorRole != 'admin_resident' &&
          creatorRole != 'gn_officer') {
        throw Exception('You do not have permission to add members.');
      }

      if (creatorRole == 'citizen' && _selectedType == MemberType.newResident) {
        throw Exception(
          'Citizens can only add family members or rental members.',
        );
      }

      final inheritedVillage = creator.village;
      final inheritedDistrict = creator.district;
      if (inheritedVillage.isEmpty || inheritedDistrict.isEmpty) {
        throw Exception(
          'Your profile is missing village/district. Update your profile before adding members.',
        );
      }

      final nic = _nicController.text.trim();
      final contactEmail = _emailController.text.trim();
      final contactPhone = _phoneController.text.trim();
      final address = _useSameAddress
          ? creator.address.trim()
          : _addressController.text.trim();

      if (address.isEmpty) {
        throw Exception('Address is required to register a member.');
      }

      if (_createSystemAccess) {
        if (nic.isEmpty) {
          throw Exception('NIC is required to create system access.');
        }
        if (contactEmail.isEmpty) {
          throw Exception('Email is required to send credentials.');
        }
      }

      if (nic.isNotEmpty) {
        final alreadyExists = await userService.isNicRegistered(nic);
        if (alreadyExists) {
          _safeSetState(() {
            _isLoading = false;
            _errorMessage = 'This NIC is already registered in the system.';
          });
          return;
        }
      }

      String newUid;
      String? password;
      String emailStatus;

      if (_createSystemAccess) {
        password = AuthService.generatePassword();
        final authEmail = Validators.nicToEmail(nic);

        newUid = await authService.createUserAccount(
          email: authEmail,
          password: password,
        );

        try {
          await credentialEmailService.queueCredentialsEmail(
            toEmail: contactEmail,
            fullName: _fullNameController.text.trim(),
            nic: nic,
            password: password,
            memberTypeLabel: _selectedType.label,
          );
          emailStatus = '✅ Login credentials were sent to $contactEmail.';
        } catch (e) {
          emailStatus =
              '⚠️ Account was created, but automatic email delivery failed (${e.toString()}). Please share the credentials manually.';
        }
      } else {
        newUid = 'member-${DateTime.now().millisecondsSinceEpoch}';
        emailStatus =
            'ℹ️ Member profile saved without system access. Credentials were not created.';
      }

      final userModel = UserModel(
        uid: newUid,
        fullName: _fullNameController.text.trim(),
        nic: nic,
        phone: contactPhone,
        email: contactEmail,
        address: address,
        village: inheritedVillage,
        district: inheritedDistrict,
        role: 'citizen',
        memberType: _selectedType,
        relationship: _selectedType == MemberType.familyMember
            ? _relationship
            : null,
        hasSystemAccess: _createSystemAccess,
        createdByUid: currentUserUid,
        createdAt: DateTime.now(),
      );

      await userService.createUserProfile(userModel);

      _safeSetState(() {
        _isLoading = false;
        _isDone = true;
        _generatedPassword = password;
        _createdUserName = _fullNameController.text.trim();
        _createdMemberType = _selectedType;
        _createdWithSystemAccess = _createSystemAccess;
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
          Expanded(
            child: _isLoadingProfile
                ? const Center(child: CircularProgressIndicator())
                : (_isDone ? _buildSuccessView() : _buildForm()),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final creatorAddress = _creatorProfile?.address.trim() ?? '';

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
            const SizedBox(height: 18),

            if (_selectedType == MemberType.familyMember) ...[
              _buildRelationshipField(),
              const SizedBox(height: 24),
            ],

            _buildToggleTile(
              title: 'Create system access for this member',
              subtitle:
                  'Turn OFF to register profile-only members (e.g., children without NIC or email).',
              value: _createSystemAccess,
              onChanged: (v) => setState(() {
                _createSystemAccess = v;
                if (!v) {
                  _generatedPassword = null;
                }
              }),
            ),
            const SizedBox(height: 28),

            Text('Personal Details', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text(
              _createSystemAccess
                  ? 'Fill all details to create login credentials.'
                  : 'Fill basic details to store this member without system login.',
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
              hint: _createSystemAccess
                  ? 'Required for system access'
                  : 'Optional (leave blank for children/no NIC)',
              icon: Icons.badge_outlined,
              validator: (v) {
                if (!_createSystemAccess && (v == null || v.trim().isEmpty)) {
                  return null;
                }
                return Validators.validateNic(v);
              },
            ),
            const SizedBox(height: 18),
            _buildFormField(
              label: 'Contact Number',
              controller: _phoneController,
              hint: _createSystemAccess
                  ? '077 123 4567'
                  : 'Optional contact number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (!_createSystemAccess && (v == null || v.trim().isEmpty)) {
                  return null;
                }
                return Validators.validatePhone(v);
              },
            ),
            const SizedBox(height: 18),
            _buildFormField(
              label: 'Email Address',
              controller: _emailController,
              hint: _createSystemAccess
                  ? 'Required to send credentials'
                  : 'Optional (can be blank)',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return _createSystemAccess
                      ? 'Email is required to send credentials'
                      : null;
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            _buildToggleTile(
              title: 'Use same address as your profile',
              subtitle:
                  'Enable to register this member under your household address.',
              value: _useSameAddress,
              onChanged: (v) {
                setState(() {
                  _useSameAddress = v;
                  if (v) {
                    _addressController.text = creatorAddress;
                  }
                });
              },
            ),
            const SizedBox(height: 12),

            if (_useSameAddress)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Text(
                  creatorAddress.isEmpty
                      ? 'Your profile address is empty. Please turn off this option and enter an address.'
                      : creatorAddress,
                  style: AppTextStyles.small.copyWith(color: AppColors.info),
                ),
              )
            else
              _buildFormField(
                label: 'Address',
                controller: _addressController,
                hint: 'Enter address',
                icon: Icons.location_on_outlined,
                maxLines: 2,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
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
        onTap: () => setState(() {
          _selectedType = type;
          if (type != MemberType.familyMember) {
            _relationship = null;
          }
        }),
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

  Widget _buildRelationshipField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Relationship', style: AppTextStyles.label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _relationship,
          onChanged: (value) => setState(() => _relationship = value),
          validator: (value) {
            if (_selectedType == MemberType.familyMember &&
                (value == null || value.isEmpty)) {
              return 'Please select relationship';
            }
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.family_restroom_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
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
            'Select relationship',
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          ),
          items: _relationships
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
          const SizedBox(height: 24),

          if (_createdWithSystemAccess) ...[
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
                  _credentialRow(
                    'Temporary Password',
                    _generatedPassword ?? '',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _emailDispatchStatus ??
                        'ℹ️ Share these credentials with the member securely.',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.primary,
                    ),
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
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Text(
                _emailDispatchStatus ??
                    'Profile-only member has been saved without login credentials.',
                style: AppTextStyles.small.copyWith(color: AppColors.info),
              ),
            ),
          ],

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
    if (_createSystemAccess) {
      return const SizedBox.shrink();
    }

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
              'ℹ️ This member will be recorded for household/government records without app access.',
              style: AppTextStyles.small.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
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
