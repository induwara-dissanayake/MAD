import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Filter options for the registered users list.
enum _UserFilter { all, citizens, committee }

class RegisteredUsersScreen extends ConsumerStatefulWidget {
  const RegisteredUsersScreen({super.key});

  @override
  ConsumerState<RegisteredUsersScreen> createState() =>
      _RegisteredUsersScreenState();
}

class _RegisteredUsersScreenState extends ConsumerState<RegisteredUsersScreen> {
  _UserFilter _activeFilter = _UserFilter.all;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Maps the current filter to a Firestore role string (null = no filter).
  String? get _roleFilter {
    switch (_activeFilter) {
      case _UserFilter.citizens:
        return 'citizen';
      case _UserFilter.committee:
        return 'committee';
      case _UserFilter.all:
        return null;
    }
  }

  List<UserModel> _applySearch(List<UserModel> users) {
    if (_searchQuery.isEmpty) return users;
    final q = _searchQuery.toLowerCase();
    return users.where((u) {
      return u.fullName.toLowerCase().contains(q) ||
          u.nic.toLowerCase().contains(q) ||
          u.phone.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userService = ref.watch(userServiceProvider);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text('Registered Users', style: AppTextStyles.h3),
        centerTitle: false,
        actions: [
          // Register new citizen shortcut
          IconButton(
            tooltip: 'Register Citizen',
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              color: AppColors.primary,
            ),
            onPressed: () => context.push('/auth/create-resident'),
          ),
          // Register committee member shortcut
          IconButton(
            tooltip: 'Register Committee Member',
            icon: const Icon(Icons.group_add_rounded, color: AppColors.primary),
            onPressed: () => context.push('/auth/add-member'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          const SizedBox(height: 4),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: userService.streamAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                var users = snapshot.data ?? [];

                // Exclude current GN Officer + other gn_officers/admins from the list
                users = users.where((u) {
                  return u.uid != currentUid &&
                      u.role != 'gn_officer' &&
                      u.role != 'admin';
                }).toList();

                // Apply role filter
                if (_roleFilter != null) {
                  users = users.where((u) => u.role == _roleFilter).toList();
                }

                // Apply search
                users = _applySearch(users);

                if (users.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _UserTile(user: users[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search by name, NIC or phone…',
          hintStyle: AppTextStyles.small.copyWith(color: AppColors.textMuted),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
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
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            icon: Icons.people_rounded,
            selected: _activeFilter == _UserFilter.all,
            onTap: () => setState(() => _activeFilter = _UserFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Citizens',
            icon: Icons.person_rounded,
            selected: _activeFilter == _UserFilter.citizens,
            onTap: () => setState(() => _activeFilter = _UserFilter.citizens),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Committee',
            icon: Icons.groups_rounded,
            selected: _activeFilter == _UserFilter.committee,
            onTap: () => setState(() => _activeFilter = _UserFilter.committee),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFiltered =
        _activeFilter != _UserFilter.all || _searchQuery.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered
                  ? Icons.search_off_rounded
                  : Icons.people_outline_rounded,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'No matching users found'
                  : 'No users registered yet',
              style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try adjusting your search or filter.'
                  : 'Register a citizen or committee member using the buttons above.',
              style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load users',
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter chip widget ───────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? AppColors.textOnPrimary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.small.copyWith(
                color: selected
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── User tile widget ─────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});
  final UserModel user;

  Color get _roleColor {
    switch (user.role) {
      case 'committee':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  String get _roleLabel {
    switch (user.role) {
      case 'committee':
        return 'Committee';
      default:
        return 'Citizen';
    }
  }

  String get _initials {
    final parts = user.fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _roleColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _initials,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _roleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName.isNotEmpty ? user.fullName : 'Unknown',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoleBadge(label: _roleLabel, color: _roleColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _InfoRow(icon: Icons.badge_outlined, text: user.nic),
                  if (user.phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    _InfoRow(icon: Icons.phone_outlined, text: user.phone),
                  ],
                  if (user.address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      text: user.address,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.maxLines = 1});

  final IconData icon;
  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.small.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
