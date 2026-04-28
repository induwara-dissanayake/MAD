import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/user_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
  String? _ownerUid;
  bool _hasSystemAccess = false;
  bool _isLoading = true;
  bool _isSubmitting = false;

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

      final data = doc.data();
      if (!mounted || data == null) return;

      _fullNameController.text = data['fullName'] as String? ?? '';
      _nicController.text = data['nic'] as String? ?? '';
      _phoneController.text = data['phone'] as String? ?? '';
      _emailController.text = data['email'] as String? ?? '';
      _ownerUid = data['createdByUid'] as String?;
      _hasSystemAccess = data['hasSystemAccess'] as bool? ?? false;

      final relationship = data['relationship'] as String?;
      if (relationship != null && _relationships.contains(relationship)) {
        _selectedRelationship = relationship;
      }
    } catch (error) {
      if (mounted) {
        _showSnack('Failed to load member details.', isError: true);
      }
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
    final ownerUid = _ownerUid?.trim();
    if (ownerUid == null || ownerUid.isEmpty) {
      _showSnack('Household owner is missing for this member.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(userServiceProvider).updateHouseholdMemberProfile(
        ownerUid: ownerUid,
        memberUid: widget.memberUid,
        data: {
          'fullName': _fullNameController.text.trim(),
          'fullNameLower': _fullNameController.text.trim().toLowerCase(),
          'nic': _nicController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'relationship': _selectedRelationship ?? '',
          'hasSystemAccess': _hasSystemAccess,
        },
      );

      if (!mounted) return;
      _showSnack('Member updated.');
      context.pop();
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ownerUid = _ownerUid?.trim();
    if (ownerUid == null || ownerUid.isEmpty) {
      _showSnack('Household owner is missing for this member.', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceIvory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Member', style: AppTextStyles.displaySmall),
        content: Text(
          'This will remove the member from your household list.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(userServiceProvider).deleteHouseholdMemberProfile(
        ownerUid: ownerUid,
        memberUid: widget.memberUid,
      );

      if (!mounted) return;
      _showSnack('Member removed.');
      context.pop();
    } catch (error) {
      if (!mounted) return;
      _showSnack('Failed to remove member.', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorRed : AppColors.brandGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceParchment,
      appBar: AppBar(
        title: const Text('Edit Member'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: _isSubmitting ? null : _confirmDelete,
            tooltip: 'Remove member',
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.errorRed,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MemberHero(hasSystemAccess: _hasSystemAccess),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Identity'),
            const SizedBox(height: 12),
            _Panel(
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Full Name',
                    controller: _fullNameController,
                    icon: Icons.person_outline,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Full name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildRelationshipField(),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'NIC',
                    controller: _nicController,
                    icon: Icons.badge_outlined,
                    validator: (value) {
                      final nic = value?.trim() ?? '';
                      if (nic.isEmpty) return null;
                      return Validators.validateNic(nic);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Contact'),
            const SizedBox(height: 12),
            _Panel(
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      final phone = value?.trim() ?? '';
                      if (phone.isEmpty) return null;
                      return Validators.validatePhone(phone);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Email Address',
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return null;
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _Panel(
              child: Row(
                children: [
                  const _IconBadge(icon: Icons.lock_outline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('System Access', style: AppTextStyles.label),
                        const SizedBox(height: 4),
                        Text(
                          _hasSystemAccess
                              ? 'This member can sign in to the app.'
                              : 'Profile-only household record.',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(
                    label: _hasSystemAccess ? 'Active' : 'No access',
                    active: _hasSystemAccess,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.brandGreen),
        filled: true,
        fillColor: AppColors.surfaceIvory,
      ),
    );
  }

  Widget _buildRelationshipField() {
    return DropdownButtonFormField<String>(
      value: _selectedRelationship,
      onChanged: (value) => setState(() => _selectedRelationship = value),
      validator: (value) =>
          value == null || value.isEmpty ? 'Please select relationship' : null,
      decoration: const InputDecoration(
        labelText: 'Relationship',
        prefixIcon: Icon(
          Icons.family_restroom_rounded,
          color: AppColors.brandGreen,
        ),
        filled: true,
        fillColor: AppColors.surfaceIvory,
      ),
      items: _relationships
          .map(
            (relationship) => DropdownMenuItem(
              value: relationship,
              child: Text(relationship),
            ),
          )
          .toList(),
    );
  }
}

class _MemberHero extends StatelessWidget {
  const _MemberHero({required this.hasSystemAccess});

  final bool hasSystemAccess;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowMedium,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(
              Icons.family_restroom_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Household Member',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasSystemAccess
                      ? 'Update this member profile.'
                      : 'Update this profile-only household record.',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceIvory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceWarmSand),
        boxShadow: AppColors.shadowLow,
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.overline.copyWith(color: AppColors.inkLight),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.brandGreenSurface,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.brandGreen, size: 20),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.brandGreenSurface : AppColors.surfaceWarmSand,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? AppColors.brandGreenBorder
              : AppColors.surfaceWarmSand,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.small.copyWith(
          color: active ? AppColors.brandGreen : AppColors.inkMid,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
