import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingPhoto = false;

  Future<void> _pickAndUploadPhoto(String uid) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceIvory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWarmSand,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Profile Photo', style: AppTextStyles.displaySmall),
              const SizedBox(height: 6),
              Text(
                'Choose a clear photo for your Village Connect profile.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 18),
              _PhotoSourceTile(
                icon: Icons.photo_library_outlined,
                title: 'Choose from gallery',
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 10),
              _PhotoSourceTile(
                icon: Icons.camera_alt_outlined,
                title: 'Take a photo',
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 512,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_pictures/$uid.jpg',
      );
      final bytes = await picked.readAsBytes();
      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'photoURL': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showSnack('Profile photo updated.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
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

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (mounted) context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authServiceProvider).currentUser;
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    if (authUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceParchment,
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: StreamBuilder<UserModel?>(
        stream: ref.read(userServiceProvider).getUserProfile(authUser.uid),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(unreadNotificationCountProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _ProfileHero(
                  authUser: authUser,
                  profile: profile,
                  uploading: _isUploadingPhoto,
                  onPhotoTap: () => _pickAndUploadPhoto(authUser.uid),
                ),
                const SizedBox(height: 20),
                _SectionHeader(
                  label: 'Account',
                  actionLabel: 'Edit',
                  onAction: () =>
                      context.push('/profile/edit-personal-information'),
                ),
                const SizedBox(height: 10),
                _InfoPanel(
                  rows: [
                    _InfoRow(
                      icon: Icons.person_outline,
                      label: 'Full name',
                      value: _fallback(profile?.fullName, authUser.displayName),
                    ),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'NIC username',
                      value: _fallback(profile?.nic, 'Not available'),
                      mono: true,
                    ),
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _fallback(profile?.email, authUser.email),
                    ),
                    _InfoRow(
                      icon: Icons.call_outlined,
                      label: 'Phone',
                      value: _fallback(profile?.phone, authUser.phoneNumber),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionHeader(label: 'Village Record'),
                const SizedBox(height: 10),
                _InfoPanel(
                  rows: [
                    _InfoRow(
                      icon: Icons.location_city_outlined,
                      label: 'Village',
                      value: _fallback(profile?.village, 'Not set'),
                    ),
                    _InfoRow(
                      icon: Icons.map_outlined,
                      label: 'District',
                      value: _fallback(profile?.district, 'Not set'),
                    ),
                    _InfoRow(
                      icon: Icons.home_outlined,
                      label: 'Address',
                      value: _fallback(profile?.address, 'Not set'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _AccessPanel(profile: profile),
                const SizedBox(height: 20),
                _HouseholdPanel(
                  profile: profile,
                  stream: profile == null
                      ? const Stream<List<UserModel>>.empty()
                      : ref
                            .read(userServiceProvider)
                            .streamHouseholdMembers(profile.uid),
                  onAdd: () => context.push('/auth/add-member'),
                  onOpen: (member) => context.push(
                    '/profile/edit-family-member',
                    extra: member.uid,
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionHeader(label: 'Actions'),
                const SizedBox(height: 10),
                _ActionPanel(
                  unreadCount: unreadCount,
                  onNotifications: () => context.push('/notifications'),
                  onHelp: () => context.push('/help'),
                  onPassword: () => context.push('/profile/change-password'),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                    side: const BorderSide(color: AppColors.errorRed),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.authUser,
    required this.profile,
    required this.uploading,
    required this.onPhotoTap,
  });

  final User authUser;
  final UserModel? profile;
  final bool uploading;
  final VoidCallback onPhotoTap;

  @override
  Widget build(BuildContext context) {
    final name = _fallback(profile?.fullName, authUser.displayName);
    final photoUrl = profile?.photoURL?.isNotEmpty == true
        ? profile!.photoURL
        : authUser.photoURL;
    final status = profile?.accountStatus ?? 'pending_first_login';

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    backgroundImage: photoUrl == null
                        ? null
                        : NetworkImage(photoUrl),
                    child: photoUrl == null
                        ? Text(
                            _initial(name),
                            style: AppTextStyles.displayLarge.copyWith(
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton.filled(
                      onPressed: uploading ? null : onPhotoTap,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceIvory,
                        foregroundColor: AppColors.brandGreen,
                        minimumSize: const Size(34, 34),
                      ),
                      icon: uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt_outlined, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.displaySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fallback(profile?.email, authUser.email),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroChip(
                          icon: Icons.verified_user_outlined,
                          label: _roleLabel(profile?.role ?? 'citizen'),
                        ),
                        _HeroChip(
                          icon: Icons.toggle_on_outlined,
                          label: _statusLabel(status),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _fallback(profile?.village, 'Village not set'),
            style: AppTextStyles.bodySemiBold.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _AccessPanel extends StatelessWidget {
  const _AccessPanel({required this.profile});

  final UserModel? profile;

  @override
  Widget build(BuildContext context) {
    final capabilities = profile?.capabilities ?? const <String, bool>{};
    final chips = <_AccessChipData>[
      _AccessChipData(
        'Committee member',
        capabilities['isCommitteeMember'] == true,
      ),
      _AccessChipData(
        'Community moderation',
        capabilities['canModerateCommunity'] == true,
      ),
      _AccessChipData(
        'Admin dashboard',
        capabilities['canAccessAdminDashboard'] == true,
      ),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(label: 'Access'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in chips)
                _StatusChip(label: chip.label, active: chip.active),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Role and capabilities are managed by GN officers or system admins.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _HouseholdPanel extends StatelessWidget {
  const _HouseholdPanel({
    required this.profile,
    required this.stream,
    required this.onAdd,
    required this.onOpen,
  });

  final UserModel? profile;
  final Stream<List<UserModel>> stream;
  final VoidCallback onAdd;
  final ValueChanged<UserModel> onOpen;

  @override
  Widget build(BuildContext context) {
    if (profile == null) return const SizedBox.shrink();

    return Column(
      children: [
        _SectionHeader(label: 'Household', actionLabel: 'Add', onAction: onAdd),
        const SizedBox(height: 10),
        StreamBuilder<List<UserModel>>(
          stream: stream,
          builder: (context, snapshot) {
            final members = snapshot.data ?? const <UserModel>[];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _Panel(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (members.isEmpty) {
              return _Panel(
                child: Row(
                  children: [
                    const _IconBadge(icon: Icons.group_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No household members yet.',
                        style: AppTextStyles.bodySemiBold,
                      ),
                    ),
                    TextButton(onPressed: onAdd, child: const Text('Add')),
                  ],
                ),
              );
            }

            return _Panel(
              child: Column(
                children: [
                  for (int i = 0; i < members.length; i++) ...[
                    _MemberRow(
                      member: members[i],
                      onTap: () => onOpen(members[i]),
                    ),
                    if (i != members.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.unreadCount,
    required this.onNotifications,
    required this.onHelp,
    required this.onPassword,
  });

  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onHelp;
  final VoidCallback onPassword;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            trailing: unreadCount > 0 ? '$unreadCount unread' : 'All clear',
            onTap: onNotifications,
          ),
          const Divider(height: 1),
          _ActionRow(
            icon: Icons.help_outline,
            label: 'Help',
            trailing: 'Guidance',
            onTap: onHelp,
          ),
          const Divider(height: 1),
          _ActionRow(
            icon: Icons.lock_outline,
            label: 'Change Password',
            trailing: 'Security',
            onTap: onPassword,
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _InfoTile(row: rows[i]),
            if (i != rows.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.row});

  final _InfoRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(icon: row.icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.label, style: AppTextStyles.small),
                const SizedBox(height: 2),
                Text(
                  row.value,
                  style: row.mono
                      ? AppTextStyles.monoMedium
                      : AppTextStyles.bodySemiBold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.onTap});

  final UserModel member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const _IconBadge(icon: Icons.person_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName.isEmpty
                        ? 'Unnamed member'
                        : member.fullName,
                    style: AppTextStyles.bodySemiBold,
                  ),
                  if (member.relationship?.isNotEmpty == true)
                    Text(member.relationship!, style: AppTextStyles.caption),
                ],
              ),
            ),
            _StatusChip(
              label: member.hasSystemAccess ? 'Active' : 'No access',
              active: member.hasSystemAccess,
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkLight),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            _IconBadge(icon: icon),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTextStyles.bodySemiBold)),
            Text(trailing, style: AppTextStyles.caption),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkLight),
          ],
        ),
      ),
    );
  }
}

class _PhotoSourceTile extends StatelessWidget {
  const _PhotoSourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceParchment,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _IconBadge(icon: icon),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: AppTextStyles.bodySemiBold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.actionLabel, this.onAction});

  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label.toUpperCase(), style: AppTextStyles.overline),
        ),
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: Icon(
              actionLabel == 'Add' ? Icons.add_rounded : Icons.edit_outlined,
            ),
            label: Text(actionLabel!),
          ),
      ],
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

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.small.copyWith(color: Colors.white)),
        ],
      ),
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

class _AccessChipData {
  const _AccessChipData(this.label, this.active);

  final String label;
  final bool active;
}

class _InfoRow {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool mono;
}

String _fallback(String? primary, String? fallback) {
  final value = primary?.trim();
  if (value != null && value.isNotEmpty) return value;
  final fallbackValue = fallback?.trim();
  if (fallbackValue != null && fallbackValue.isNotEmpty) return fallbackValue;
  return 'Not available';
}

String _initial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed[0].toUpperCase();
}

String _roleLabel(String role) {
  switch (role) {
    case 'gn_officer':
      return 'GN Officer';
    case 'admin':
    case 'super_admin':
      return 'Admin';
    case 'committee':
      return 'Committee';
    case 'admin_resident':
      return 'Resident Admin';
    default:
      return 'Citizen';
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'pending_first_login':
      return 'Pending first login';
    case 'inactive':
      return 'Inactive';
    case 'suspended':
      return 'Suspended';
    default:
      return 'Active';
  }
}
