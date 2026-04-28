import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  final _searchController = TextEditingController();
  String _searchType = 'nic';
  AdminUserModel? _selectedUser;
  bool _isSearching = false;
  bool _isSaving = false;

  String _draftRole = 'citizen';
  AccountStatus _draftStatus = AccountStatus.active;
  Map<String, bool> _draftCapabilities = const {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectUser(AdminUserModel user) {
    setState(() {
      _selectedUser = user;
      _draftRole = _normalizeRole(user.role);
      _draftStatus = user.accountStatus;
      _draftCapabilities = Map<String, bool>.from(user.capabilities);
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _showSnack('Enter a NIC, phone, or name to search.');
      return;
    }

    setState(() => _isSearching = true);
    try {
      AdminUserModel? user;
      if (_searchType == 'nic') {
        user = await ref.read(searchUserByNicProvider(query).future);
      } else if (_searchType == 'phone') {
        user = await ref.read(searchUserByPhoneProvider(query).future);
      } else {
        final matches = await ref.read(searchUsersByNameProvider(query).future);
        if (matches.isNotEmpty) user = matches.first;
      }

      if (!mounted) return;
      if (user == null) {
        _showSnack('No matching user found.');
      } else {
        _selectUser(user);
      }
    } catch (error) {
      if (mounted) _showSnack('Search failed: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _saveFirestoreChanges() async {
    final user = _selectedUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      if (_draftRole != _normalizeRole(user.role)) {
        await ref.read(
          updateUserRoleProvider((uid: user.uid, newRole: _draftRole)).future,
        );
      }

      final newStatus = _statusKey(_draftStatus);
      final currentStatus = _statusKey(user.accountStatus);
      if (newStatus != currentStatus) {
        await ref.read(
          updateUserAccountStatusProvider((
            uid: user.uid,
            status: newStatus,
          )).future,
        );
      }

      await ref.read(
        updateUserCapabilitiesProvider((
          uid: user.uid,
          capabilities: _draftCapabilities,
        )).future,
      );

      ref.invalidate(currentUsersProvider);
      if (!mounted) return;
      setState(() {
        _selectedUser = user.copyWith(
          role: _draftRole,
          accountStatus: _draftStatus,
          capabilities: Map<String, bool>.from(_draftCapabilities),
        );
      });
      _showSnack('Firestore user profile updated.');
    } catch (error) {
      if (mounted) _showSnack('Save failed: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(currentUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceParchment,
      appBar: AppBar(
        title: const Text('User Management'),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin/dashboard');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () => context.go('/admin/create-user'),
            tooltip: 'Create user',
            icon: const Icon(Icons.person_add_alt_outlined),
          ),
          IconButton(
            onPressed: () => ref.invalidate(currentUsersProvider),
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 840;
          final list = _UserListPanel(
            usersAsync: usersAsync,
            selectedUid: _selectedUser?.uid,
            onSelect: _selectUser,
          );
          final editor = _selectedUser == null
              ? const _NoSelectionPanel()
              : _EditorPanel(
                  user: _selectedUser!,
                  role: _draftRole,
                  status: _draftStatus,
                  capabilities: _draftCapabilities,
                  isSaving: _isSaving,
                  onRoleChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _draftRole = value;
                      _draftCapabilities = _capabilitiesForRole(
                        value,
                        _draftCapabilities,
                      );
                    });
                  },
                  onStatusChanged: (value) {
                    if (value == null) return;
                    setState(() => _draftStatus = value);
                  },
                  onCapabilityChanged: (key, value) {
                    setState(() {
                      _draftCapabilities = {..._draftCapabilities, key: value};
                    });
                  },
                  onSave: _saveFirestoreChanges,
                  onDelete: _showDeleteDialog,
                );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _AdminUserHero(onCreate: () => context.go('/admin/create-user')),
              const SizedBox(height: 18),
              _SearchPanel(
                controller: _searchController,
                searchType: _searchType,
                isSearching: _isSearching,
                onTypeChanged: (value) => setState(() => _searchType = value),
                onSearch: _performSearch,
              ),
              const SizedBox(height: 18),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 360, child: list),
                    const SizedBox(width: 18),
                    Expanded(child: editor),
                  ],
                )
              else ...[
                list,
                const SizedBox(height: 18),
                editor,
              ],
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog() {
    final user = _selectedUser;
    if (user == null) return;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Firestore profile?'),
        content: Text(
          'This removes ${user.fullName} from Firestore users plus related requests and notifications. Firebase Auth account deletion still needs backend admin tooling.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSelectedUser();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text('Delete profile'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedUser() async {
    final user = _selectedUser;
    if (user == null) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(deleteUserProvider(user.uid).future);
      ref.invalidate(currentUsersProvider);
      if (!mounted) return;
      setState(() => _selectedUser = null);
      _showSnack('Firestore profile deleted.');
    } catch (error) {
      if (mounted) _showSnack('Delete failed: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }
}

class _AdminUserHero extends StatelessWidget {
  const _AdminUserHero({required this.onCreate});

  final VoidCallback onCreate;

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
            'Firestore User Control',
            style: AppTextStyles.displaySmall.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Search a profile, edit role/status/capabilities, and keep audit-friendly Firestore changes in one place.',
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.brandGreen,
            ),
            icon: const Icon(Icons.person_add_alt_outlined),
            label: const Text('Register citizen / user'),
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.searchType,
    required this.isSearching,
    required this.onTypeChanged,
    required this.onSearch,
  });

  final TextEditingController controller;
  final String searchType;
  final bool isSearching;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Find User'),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            selected: {searchType},
            onSelectionChanged: (selection) => onTypeChanged(selection.first),
            segments: const [
              ButtonSegment(value: 'nic', label: Text('NIC')),
              ButtonSegment(value: 'phone', label: Text('Phone')),
              ButtonSegment(value: 'name', label: Text('Name')),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: switch (searchType) {
                'phone' => 'Search exact phone number',
                'name' => 'Search by resident name',
                _ => 'Search exact NIC number',
              },
              prefixIcon: const Icon(Icons.search_outlined),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSearching ? null : onSearch,
              icon: isSearching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.manage_search_outlined),
              label: Text(isSearching ? 'Searching...' : 'Search Firestore'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserListPanel extends StatelessWidget {
  const _UserListPanel({
    required this.usersAsync,
    required this.selectedUid,
    required this.onSelect,
  });

  final AsyncValue<List<AdminUserModel>> usersAsync;
  final String? selectedUid;
  final ValueChanged<AdminUserModel> onSelect;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Recent Profiles'),
          const SizedBox(height: 10),
          usersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text(
              'Unable to load recent users: $error',
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
            data: (users) {
              if (users.isEmpty) {
                return Text(
                  'No user profiles found.',
                  style: AppTextStyles.caption,
                );
              }
              return Column(
                children: [
                  for (final user in users.take(30))
                    _UserRow(
                      user: user,
                      selected: user.uid == selectedUid,
                      onTap: () => onSelect(user),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.selected,
    required this.onTap,
  });

  final AdminUserModel user;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.brandGreenSurface
                  : AppColors.surfaceParchment,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppColors.brandGreenBorder
                    : AppColors.surfaceWarmSand,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.brandGreenSurface,
                  foregroundColor: AppColors.brandGreen,
                  child: Text(_initial(user.fullName)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName.isEmpty ? 'Unnamed user' : user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySemiBold,
                      ),
                      Text(
                        '${user.nic} - ${_prettyRole(user.role)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.small,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.inkLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorPanel extends StatelessWidget {
  const _EditorPanel({
    required this.user,
    required this.role,
    required this.status,
    required this.capabilities,
    required this.isSaving,
    required this.onRoleChanged,
    required this.onStatusChanged,
    required this.onCapabilityChanged,
    required this.onSave,
    required this.onDelete,
  });

  final AdminUserModel user;
  final String role;
  final AccountStatus status;
  final Map<String, bool> capabilities;
  final bool isSaving;
  final ValueChanged<String?> onRoleChanged;
  final ValueChanged<AccountStatus?> onStatusChanged;
  final void Function(String key, bool value) onCapabilityChanged;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.brandGreenSurface,
                foregroundColor: AppColors.brandGreen,
                child: Text(_initial(user.fullName), style: AppTextStyles.h3),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isEmpty ? 'Unnamed user' : user.fullName,
                      style: AppTextStyles.h3,
                    ),
                    Text(user.email, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _FirestoreFields(user: user),
          const SizedBox(height: 22),
          const _SectionLabel('Access Controls'),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: role,
            decoration: const InputDecoration(
              labelText: 'Role',
              prefixIcon: Icon(Icons.admin_panel_settings_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'citizen', child: Text('Citizen')),
              DropdownMenuItem(value: 'gn_officer', child: Text('GN Officer')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: isSaving ? null : onRoleChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AccountStatus>(
            initialValue: status,
            decoration: const InputDecoration(
              labelText: 'Account status',
              prefixIcon: Icon(Icons.toggle_on_outlined),
            ),
            items: const [
              DropdownMenuItem(
                value: AccountStatus.pendingFirstLogin,
                child: Text('Pending first login'),
              ),
              DropdownMenuItem(
                value: AccountStatus.active,
                child: Text('Active'),
              ),
              DropdownMenuItem(
                value: AccountStatus.inactive,
                child: Text('Inactive'),
              ),
              DropdownMenuItem(
                value: AccountStatus.suspended,
                child: Text('Suspended'),
              ),
            ],
            onChanged: isSaving ? null : onStatusChanged,
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Capabilities'),
          const SizedBox(height: 8),
          _CapabilitySwitch(
            title: 'Committee member',
            subtitle: 'Can appear as village committee support.',
            value: capabilities['isCommitteeMember'] == true,
            onChanged: isSaving
                ? null
                : (value) => onCapabilityChanged('isCommitteeMember', value),
          ),
          _CapabilitySwitch(
            title: 'Moderate community',
            subtitle: 'Can approve or remove community posts.',
            value: capabilities['canModerateCommunity'] == true,
            onChanged: isSaving
                ? null
                : (value) => onCapabilityChanged('canModerateCommunity', value),
          ),
          _CapabilitySwitch(
            title: 'Admin dashboard access',
            subtitle: 'Can open /admin dashboard and management screens.',
            value: capabilities['canAccessAdminDashboard'] == true,
            onChanged: isSaving
                ? null
                : (value) =>
                      onCapabilityChanged('canAccessAdminDashboard', value),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                isSaving ? 'Saving Firestore...' : 'Save Firestore Changes',
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Firestore Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorRed,
                side: const BorderSide(color: AppColors.errorRed),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FirestoreFields extends StatelessWidget {
  const _FirestoreFields({required this.user});

  final AdminUserModel user;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('UID', user.uid),
      ('NIC', user.nic),
      ('Phone', user.phone),
      ('Village', user.village),
      ('Address', user.address),
      ('Created', DateFormat.yMMMd().format(user.createdAt)),
      if (user.lastLogin != null)
        ('Last login', DateFormat.yMMMd().add_jm().format(user.lastLogin!)),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceParchment,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceWarmSand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Firestore Profile'),
          const SizedBox(height: 10),
          for (final row in rows) _FieldRow(label: row.$1, value: row.$2),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 86, child: Text(label, style: AppTextStyles.small)),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: label == 'UID'
                  ? AppTextStyles.monoMedium
                  : AppTextStyles.caption.copyWith(color: AppColors.inkBlack),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapabilitySwitch extends StatelessWidget {
  const _CapabilitySwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTextStyles.bodySemiBold),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.brandGreen,
    );
  }
}

class _NoSelectionPanel extends StatelessWidget {
  const _NoSelectionPanel();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Icon(
              Icons.manage_accounts_outlined,
              size: 48,
              color: AppColors.inkLight,
            ),
            SizedBox(height: 12),
            Text('Select a user to manage Firestore access.'),
          ],
        ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(), style: AppTextStyles.overline);
  }
}

Map<String, bool> _capabilitiesForRole(String role, Map<String, bool> current) {
  return {
    ...current,
    'isCommitteeMember': current['isCommitteeMember'] == true,
    'canModerateCommunity': role == 'gn_officer'
        ? true
        : current['canModerateCommunity'] == true,
    'canAccessAdminDashboard': role == 'admin'
        ? true
        : current['canAccessAdminDashboard'] == true,
  };
}

String _normalizeRole(String role) {
  if (role == 'super_admin') return 'admin';
  if (role == 'admin_resident' || role == 'committee') return 'citizen';
  if (role == 'gn_officer' || role == 'admin') return role;
  return 'citizen';
}

String _prettyRole(String role) => _normalizeRole(role).replaceAll('_', ' ');

String _statusKey(AccountStatus status) {
  switch (status) {
    case AccountStatus.pendingFirstLogin:
      return 'pending_first_login';
    case AccountStatus.active:
      return 'active';
    case AccountStatus.inactive:
      return 'inactive';
    case AccountStatus.suspended:
      return 'suspended';
  }
}

String _initial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.first.toUpperCase();
}
