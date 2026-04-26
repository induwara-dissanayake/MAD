import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingPhoto = false;

  Future<void> _pickAndUploadPhoto(String uid) async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFBFCABA).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Profile Picture',
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.02 * 22,
                color: Color(0xFF1A1C1C),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose how to update your photo.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: const Color(0xFF1A1C1C).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            _buildBottomSheetTile(
              icon: Icons.photo_library_outlined,
              title: 'Choose from Gallery',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
            _buildBottomSheetTile(
              icon: Icons.camera_alt_outlined,
              title: 'Take a Photo',
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 512,
    );

    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'profile_pictures/$uid.jpg',
      );
      final bytes = await picked.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'photoURL': url,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile picture updated successfully.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Widget _buildBottomSheetTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF3F3F3),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0d631b).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF0d631b), size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1C1C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: const Color(0xFF1A1C1C).withOpacity(0.04),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1C1C)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontFamily: 'PublicSans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02 * 18,
            color: Color(0xFF1A1C1C),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFBFCABA).withOpacity(0.15),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: StreamBuilder<UserModel?>(
          stream: ref.read(userServiceProvider).getUserProfile(user.uid),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            return Column(
              children: [
                _buildProfileHeader(user, profile),
                const SizedBox(height: 32),
                _buildSectionLabel('Personal'),
                const SizedBox(height: 10),
                _buildPersonalInfo(context, user, profile),
                const SizedBox(height: 28),
                _buildSectionLabel('Village'),
                const SizedBox(height: 10),
                _buildVillageInfo(profile),
                const SizedBox(height: 28),
                _buildSectionLabel('Household'),
                const SizedBox(height: 10),
                _buildFamilyMembers(context, profile),
                const SizedBox(height: 28),
                _buildSectionLabel('Quick Access'),
                const SizedBox(height: 10),
                _buildShortcutsSection(
                  context,
                  ref.watch(unreadNotificationCountProvider),
                ),
                const SizedBox(height: 28),
                _buildSectionLabel('Preferences'),
                const SizedBox(height: 10),
                _buildSettingsSection(context),
                const SizedBox(height: 32),
                _buildLogoutButton(context, ref),
                const SizedBox(height: 48),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Color(0xFF0d631b),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFF0d631b).withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile Header ────────────────────────────────────────────────────
  String _roleLabel(String role) {
    switch (role) {
      case 'gn_officer':
        return 'GN Officer';
      case 'admin_resident':
        return 'Resident Admin';
      case 'admin':
        return 'Admin';
      case 'committee':
        return 'Committee';
      default:
        return 'Citizen';
    }
  }

  Widget _buildProfileHeader(User user, UserModel? profile) {
    final displayName = profile?.fullName ?? user.displayName ?? 'Citizen';
    final role = _roleLabel(profile?.role ?? 'citizen');
    final initials = displayName.substring(0, 1).toUpperCase();
    final photoURL = (profile?.photoURL?.isNotEmpty == true)
        ? profile!.photoURL
        : user.photoURL;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0d631b), Color(0xFF2e7d32)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background texture dots
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 2,
                          ),
                          image: photoURL != null
                              ? DecorationImage(
                                  image: NetworkImage(photoURL),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: photoURL == null
                            ? Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    fontFamily: 'PublicSans',
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingPhoto
                              ? null
                              : () => _pickAndUploadPhoto(user.uid),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _isUploadingPhoto
                                ? const Padding(
                                    padding: EdgeInsets.all(5),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0d631b),
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 15,
                                    color: Color(0xFF0d631b),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.02 * 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile?.email.isNotEmpty == true
                        ? profile!.email
                        : (user.email ?? 'No Email'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.65),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Role & Village chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$role  ·  ${profile?.village.isNotEmpty == true ? profile!.village : 'Village'}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Personal Information ──────────────────────────────────────────────
  Widget _buildPersonalInfo(
    BuildContext context,
    User user,
    UserModel? profile,
  ) {
    final fullName = profile?.fullName ?? user.displayName ?? 'N/A';
    final email = profile?.email ?? user.email ?? 'N/A';
    final phone = profile?.phone ?? user.phoneNumber ?? 'N/A';
    return _buildInfoSection(
      title: 'Personal Information',
      onTap: () => context.push('/profile/edit-personal-information'),
      items: [
        _InfoRow(Icons.person_outline_rounded, 'Full Name', fullName),
        _InfoRow(Icons.email_outlined, 'Email', email),
        _InfoRow(Icons.phone_outlined, 'Phone', phone),
        _InfoRow(
          Icons.verified_user_outlined,
          'User ID',
          user.uid.substring(0, 8),
        ),
      ],
    );
  }

  // ── Village Information ───────────────────────────────────────────────
  Widget _buildVillageInfo(UserModel? profile) {
    return _buildInfoSection(
      title: 'Village Details',
      onTap: null,
      items: [
        _InfoRow(
          Icons.holiday_village_outlined,
          'Village',
          profile?.village ?? 'N/A',
        ),
        _InfoRow(
          Icons.location_on_outlined,
          'GN Division',
          profile?.village ?? 'N/A',
        ),
        _InfoRow(Icons.map_outlined, 'District', profile?.district ?? 'N/A'),
        _InfoRow(Icons.home_outlined, 'Address', profile?.address ?? 'N/A'),
      ],
    );
  }

  // ── Family Members ────────────────────────────────────────────────────
  Widget _buildFamilyMembers(BuildContext context, UserModel? profile) {
    if (profile == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Family Members',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1C1C),
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/auth/add-member'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0d631b), Color(0xFF2e7d32)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('createdByUid', isEqualTo: profile.uid)
                .where('memberType', isEqualTo: MemberType.familyMember.key)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0d631b).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.group_outlined,
                          size: 20,
                          color: Color(0xFF0d631b),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No members yet',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1C1C),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Tap Add to register a family member.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: Color(0xFF1A1C1C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final members = docs
                  .map(
                    (d) => UserModel.fromMap(
                      d.data() as Map<String, dynamic>,
                      d.id,
                    ),
                  )
                  .toList();

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A1C1C).withOpacity(0.05),
                      blurRadius: 32,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    children: members.asMap().entries.map((entry) {
                      final member = entry.value;
                      final isLast = entry.key == members.length - 1;
                      return Column(
                        children: [
                          _buildFamilyMemberCard(
                            context,
                            member,
                            isFirst: entry.key == 0,
                            isLast: isLast,
                          ),
                          if (!isLast)
                            Container(
                              height: 1,
                              margin: const EdgeInsets.only(left: 56),
                              color: const Color(0xFFBFCABA).withOpacity(0.15),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Single Family Member Card ─────────────────────────────────────────
  Widget _buildFamilyMemberCard(
    BuildContext context,
    UserModel member, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            context.push('/profile/edit-family-member', extra: member.uid),
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(14) : Radius.zero,
          bottom: isLast ? const Radius.circular(14) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF0d631b).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 18,
                  color: Color(0xFF0d631b),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName.isNotEmpty ? member.fullName : 'N/A',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1C1C),
                      ),
                    ),
                    if (member.relationship?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        member.relationship!,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: const Color(0xFF1A1C1C).withOpacity(0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: member.hasSystemAccess
                      ? const Color(0xFF0d631b).withOpacity(0.08)
                      : const Color(0xFFBFCABA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  member.hasSystemAccess ? 'Active' : 'No Access',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: member.hasSystemAccess
                        ? const Color(0xFF0d631b)
                        : const Color(0xFF1A1C1C).withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFF1A1C1C).withOpacity(0.25),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared Info Section ───────────────────────────────────────────────
  Widget _buildInfoSection({
    required String title,
    required List<_InfoRow> items,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onTap != null)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0d631b).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 13,
                        color: Color(0xFF0d631b),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0d631b),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (onTap != null) const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A1C1C).withOpacity(0.05),
                  blurRadius: 32,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                children: items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final isLast = entry.key == items.length - 1;
                  return Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.vertical(
                            top: entry.key == 0
                                ? const Radius.circular(14)
                                : Radius.zero,
                            bottom: isLast
                                ? const Radius.circular(14)
                                : Radius.zero,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF0d631b,
                                    ).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 18,
                                    color: const Color(0xFF0d631b),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.label,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: const Color(
                                            0xFF1A1C1C,
                                          ).withOpacity(0.5),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.value,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1A1C1C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        Container(
                          height: 1,
                          margin: const EdgeInsets.only(left: 66),
                          color: const Color(0xFFBFCABA).withOpacity(0.15),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shortcuts ─────────────────────────────────────────────────────────
  Widget _buildShortcutsSection(BuildContext context, int unreadCount) {
    return _buildTileGroup([
      _buildNavTile(
        icon: Icons.notifications_none_rounded,
        title: 'Alerts',
        isFirst: true,
        onTap: () => context.push('/notifications'),
        unreadCount: unreadCount,
      ),
      _buildNavTile(
        icon: Icons.help_outline_rounded,
        title: 'Help',
        isLast: true,
        onTap: () => context.push('/help'),
      ),
    ]);
  }

  // ── Settings ──────────────────────────────────────────────────────────
  Widget _buildSettingsSection(BuildContext context) {
    return _buildTileGroup([
      _buildNavTile(
        icon: Icons.translate_rounded,
        title: 'Language',
        trailing: 'English',
        isFirst: true,
        onTap: () {},
      ),
      _buildNavTile(
        icon: Icons.notifications_none_rounded,
        title: 'Notifications',
        trailing: 'Enabled',
        onTap: () {},
      ),
      _buildNavTile(
        icon: Icons.security_rounded,
        title: 'Change Password',
        isLast: true,
        onTap: () => context.push('/profile/change-password'),
      ),
    ]);
  }

  Widget _buildTileGroup(List<Widget> tiles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1C1C).withOpacity(0.05),
              blurRadius: 32,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(children: tiles),
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? trailing,
    int unreadCount = 0,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.vertical(
              top: isFirst ? const Radius.circular(14) : Radius.zero,
              bottom: isLast ? const Radius.circular(14) : Radius.zero,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0d631b).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: const Color(0xFF0d631b)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1C1C),
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    Text(
                      trailing,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: const Color(0xFF1A1C1C).withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (unreadCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ],
                  Icon(
                    Icons.chevron_right_rounded,
                    color: const Color(0xFF1A1C1C).withOpacity(0.25),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 66),
            color: const Color(0xFFBFCABA).withOpacity(0.15),
          ),
      ],
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: () async {
            await ref.read(authServiceProvider).signOut();
          },
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text(
            'Sign Out',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: BorderSide(color: AppColors.error.withOpacity(0.4), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);
}
