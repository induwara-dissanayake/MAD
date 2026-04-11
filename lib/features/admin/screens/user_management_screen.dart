import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/admin_user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controllers/admin_controller.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  late final TextEditingController _searchController;
  String _searchType = 'nic'; // 'nic', 'phone', 'name'
  AdminUserModel? _selectedUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a search value')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedUser = null;
    });

    try {
      AdminUserModel? result;

      if (_searchType == 'nic') {
        result = await ref.read(
          searchUserByNicProvider(_searchController.text.trim()).future,
        );
      } else if (_searchType == 'phone') {
        result = await ref.read(
          searchUserByPhoneProvider(_searchController.text.trim()).future,
        );
      } else {
        final results = await ref.read(
          searchUsersByNameProvider(_searchController.text.trim()).future,
        );
        if (results.isNotEmpty) {
          result = results.first;
        }
      }

      setState(() {
        _selectedUser = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Management'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchSection(),
            const SizedBox(height: 24),
            if (_selectedUser != null) ...[
              _buildUserDetailsCard(),
              const SizedBox(height: 24),
              _buildManagementSection(),
            ] else if (_isLoading) ...[
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Searching...',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 64,
                        color: AppColors.textMuted.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No user selected',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use the search above to find a user',
                        style: AppTextStyles.small
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search User',
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
              Text(
                'Search By',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'nic',
                    label: Text('NIC'),
                  ),
                  ButtonSegment<String>(
                    value: 'phone',
                    label: Text('Phone'),
                  ),
                  ButtonSegment<String>(
                    value: 'name',
                    label: Text('Name'),
                  ),
                ],
                selected: <String>{_searchType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _searchType = newSelection.first;
                    _selectedUser = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _getSearchHint(),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceGrey,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                onSubmitted: (_) => _performSearch(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _performSearch,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Search'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getSearchHint() {
    switch (_searchType) {
      case 'nic':
        return 'Enter NIC number...';
      case 'phone':
        return 'Enter phone number...';
      default:
        return 'Enter full name...';
    }
  }

  Widget _buildUserDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _selectedUser!.fullName.split(' ').map((w) => w[0]).join(),
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedUser!.fullName,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedUser!.email,
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 16),
          const SizedBox(height: 8),
          _buildDetailRow('NIC', _selectedUser!.nic),
          const SizedBox(height: 8),
          _buildDetailRow('Phone', _selectedUser!.phone),
          const SizedBox(height: 8),
          _buildDetailRow('Village', _selectedUser!.village),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Current Role',
            _selectedUser!.role.replaceAll('_', ' ').toLowerCase(),
            roleTag: true,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Account Status',
            _selectedUser!.accountStatus.value,
            statusTag: true,
            status: _selectedUser!.accountStatus,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Created',
            _formatDate(_selectedUser!.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool roleTag = false,
    bool statusTag = false,
    AccountStatus? status,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.small
              .copyWith(color: AppColors.textSecondary, fontSize: 12),
        ),
        if (roleTag)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: AppTextStyles.small.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          )
        else if (statusTag && status != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: status.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: AppTextStyles.small.copyWith(
                color: status.statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          )
        else
          Text(
            value,
            style: AppTextStyles.small.copyWith(
              color: AppColors.textPrimary,
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manage Account',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _buildManagementTile(
          title: 'Change Role',
          subtitle: 'Update user role',
          icon: Icons.security_rounded,
          color: AppColors.primary,
          onTap: () => _showRoleDialog(),
        ),
        const SizedBox(height: 12),
        _buildManagementTile(
          title: 'Change Account Status',
          subtitle: 'Activate, deactivate, or suspend account',
          icon: Icons.toggle_on_rounded,
          color: AppColors.warning,
          onTap: () => _showStatusDialog(),
        ),
      ],
    );
  }

  Widget _buildManagementTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.small
                          .copyWith(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoleDialog() {
    if (_selectedUser == null) return;

    String selectedRole = _selectedUser!.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Change User Role',
            style: AppTextStyles.h3,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedUser!.fullName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedUser!.email,
                  style: AppTextStyles.small,
                ),
                const SizedBox(height: 20),
                Text(
                  'Select New Role',
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: 12),
                ...[
                  'citizen',
                  'gn_officer',
                  'committee',
                  'admin',
                  'super_admin'
                ].map((role) {
                  return RadioListTile<String>(
                    title: Text(role.replaceAll('_', ' ')),
                    value: role,
                    groupValue: selectedRole,
                    onChanged: (v) =>
                        setDialogState(() => selectedRole = v ?? selectedRole),
                    activeColor: AppColors.primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedRole == _selectedUser!.role
                  ? null
                  : () {
                      _updateUserRole(selectedRole);
                      Navigator.pop(context);
                    },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusDialog() {
    if (_selectedUser == null) return;

    AccountStatus selectedStatus = _selectedUser!.accountStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Change Account Status',
            style: AppTextStyles.h3,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedUser!.fullName,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ...[
                AccountStatus.active,
                AccountStatus.inactive,
                AccountStatus.suspended
              ].map((status) {
                return RadioListTile<AccountStatus>(
                  title: Text(status.value),
                  value: status,
                  groupValue: selectedStatus,
                  onChanged: (v) =>
                      setDialogState(() => selectedStatus = v ?? selectedStatus),
                  activeColor: status.statusColor,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedStatus == _selectedUser!.accountStatus
                  ? null
                  : () {
                      _updateUserStatus(selectedStatus);
                      Navigator.pop(context);
                    },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUserRole(String newRole) async {
    if (_selectedUser == null) return;

    try {
      await ref.read(
        updateUserRoleProvider(
          (uid: _selectedUser!.uid, newRole: newRole),
        ).future,
      );

      setState(() {
        _selectedUser = _selectedUser!.copyWith(role: newRole);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Role updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateUserStatus(AccountStatus newStatus) async {
    if (_selectedUser == null) return;

    try {
      await ref.read(
        updateUserAccountStatusProvider(
          (uid: _selectedUser!.uid, status: newStatus.value.toLowerCase()),
        ).future,
      );

      setState(() {
        _selectedUser = _selectedUser!.copyWith(accountStatus: newStatus);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account status updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
