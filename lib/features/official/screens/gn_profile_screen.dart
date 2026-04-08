import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class GnProfileScreen extends StatefulWidget {
  const GnProfileScreen({super.key});

  @override
  State<GnProfileScreen> createState() => _GnProfileScreenState();
}

class _GnProfileScreenState extends State<GnProfileScreen> {
  final String _name = 'Nimal Fernando';
  final String _initials = 'NF';
  final String _nic = '197812345678';
  final String _phone = '+94 77 123 4567';
  final String _division = 'Division 521 — Kaduwela';
  final String _district = 'Colombo';
  final String _status = 'Active';
  final String _created = '01 January 2024';
  final String _lastLogin = 'Today at 09:14 AM';

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      context.go('/auth/login');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out. Please try again.')),
      );
    }
  }

  Widget _buildProfileHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _name,
            style: AppTextStyles.h2.copyWith(color: AppColors.textOnPrimary),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  'Grama Niladhari Officer',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _division,
            style: AppTextStyles.captionMedium.copyWith(
              color: AppColors.textOnPrimary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String sectionTitle, List<_ProfileItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sectionTitle, style: AppTextStyles.h3),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              return Column(
                children: [
                  _buildInfoRow(items[index]),
                  if (index < items.length - 1)
                    Divider(color: AppColors.divider, height: 1),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(_ProfileItem item) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(item.value, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color titleColor = AppColors.textPrimary,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodySemiBold.copyWith(
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.small),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Log Out?',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You will be signed out of Village Connect.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => dialogContext.pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      dialogContext.pop();
                      await _logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                      elevation: 0,
                    ),
                    child: const Text('Log Out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet() {
    final nameCtrl = TextEditingController(text: _name);
    final phoneCtrl = TextEditingController(text: _phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
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
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Edit Profile', style: AppTextStyles.h3),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Full Name', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card,
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Official Phone', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card,
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Profile updated successfully'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save Changes',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text('My Profile', style: AppTextStyles.h3),
        actions: [
          TextButton(
            onPressed: _showEditSheet,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: AppTextStyles.buttonSmall,
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildProfileHero(),
            const SizedBox(height: 24),
            _buildInfoCard('Account Information', [
              _ProfileItem(Icons.badge_outlined, 'NIC Number', _nic),
              _ProfileItem(Icons.phone_outlined, 'Official Phone', _phone),
              _ProfileItem(
                Icons.location_city_outlined,
                'GN Division',
                _division,
              ),
              _ProfileItem(Icons.map_outlined, 'District', _district),
            ]),
            const SizedBox(height: 24),
            _buildInfoCard('Account Status', [
              _ProfileItem(
                Icons.check_circle_outline_rounded,
                'Status',
                _status,
              ),
              _ProfileItem(
                Icons.calendar_today_outlined,
                'Account Created',
                _created,
              ),
              _ProfileItem(Icons.update_rounded, 'Last Login', _lastLogin),
            ]),
            const SizedBox(height: 24),
            Text('Account Actions', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            _buildActionTile(
              icon: Icons.lock_outline_rounded,
              iconBg: AppColors.infoLight,
              iconColor: AppColors.info,
              title: 'Change Password',
              onTap: () => context.push('/profile/change-password'),
            ),
            const SizedBox(height: 10),
            _buildActionTile(
              icon: Icons.help_outline_rounded,
              iconBg: AppColors.successLight,
              iconColor: AppColors.success,
              title: 'Help & Support',
              onTap: () => context.push('/help'),
            ),
            const SizedBox(height: 10),
            _buildActionTile(
              icon: Icons.logout_rounded,
              iconBg: AppColors.errorLight,
              iconColor: AppColors.error,
              title: 'Log Out',
              titleColor: AppColors.error,
              onTap: _showLogoutDialog,
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Village Connect v1.0.0 · GN Officer',
                style: AppTextStyles.small,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileItem(this.icon, this.label, this.value);
}
