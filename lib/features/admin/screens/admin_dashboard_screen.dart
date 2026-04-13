import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controllers/admin_controller.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userCountAsync = ref.watch(getUserCountByRoleProvider);
    final requestMetricsAsync = ref.watch(requestMetricsProvider);
    final noticeCountAsync = ref.watch(noticeCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              // Refresh all providers
              ref.invalidate(getUserCountByRoleProvider);
              ref.invalidate(requestMetricsProvider);
              ref.invalidate(noticeCountProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            _buildWelcomeHeader(),
            const SizedBox(height: 24),

            _buildManagementBanner(context),
            const SizedBox(height: 24),

            // Quick Stats - Row 1 (User & Request Metrics)
            _buildQuickStatsRow1(userCountAsync, requestMetricsAsync),
            const SizedBox(height: 16),

            // Quick Stats - Row 2 (Notice & System Info)
            _buildQuickStatsRow2(noticeCountAsync, requestMetricsAsync),
            const SizedBox(height: 24),

            // ━━━━━━ Request Management Section ━━━━━━
            _buildSectionHeader('Request Management'),
            const SizedBox(height: 12),
            _buildActionGrid(context),
            const SizedBox(height: 24),

            // ━━━━━━ User Management Section ━━━━━━
            _buildSectionHeader('User Management'),
            const SizedBox(height: 12),
            _buildUserManagementActions(context),
            const SizedBox(height: 24),

            // ━━━━━━ System Info Section ━━━━━━
            _buildSectionHeader('System Information'),
            const SizedBox(height: 12),
            _buildSystemInfo(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, Admin',
          style: AppTextStyles.h1.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage system users, requests, and notices',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatsRow1(
    AsyncValue<Map<String, int>> userCountAsync,
    AsyncValue<({int pending, int approved, int rejected, int total})>
        requestMetricsAsync,
  ) {
    return Row(
      children: [
        Expanded(
          child: userCountAsync.when(
            loading: () => _buildStatCardSkeleton(),
            error: (_, __) => _buildStatCard(
              'Users',
              '0',
              Icons.people_rounded,
              AppColors.primary,
            ),
            data: (counts) {
              final total = counts.values.fold(0, (a, b) => a + b);
              return _buildStatCard(
                'Total Users',
                '$total',
                Icons.people_rounded,
                AppColors.primary,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: requestMetricsAsync.when(
            loading: () => _buildStatCardSkeleton(),
            error: (_, __) => _buildStatCard(
              'Requests',
              '0',
              Icons.description_rounded,
              AppColors.info,
            ),
            data: (metrics) => _buildStatCard(
              'Total Requests',
              '${metrics.total}',
              Icons.description_rounded,
              AppColors.info,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatsRow2(
    AsyncValue<int> noticeCountAsync,
    AsyncValue<({int pending, int approved, int rejected, int total})>
        requestMetricsAsync,
  ) {
    return Row(
      children: [
        Expanded(
          child: requestMetricsAsync.when(
            loading: () => _buildStatCardSkeleton(),
            error: (_, __) => _buildStatCard(
              'Pending',
              '0',
              Icons.hourglass_bottom_rounded,
              AppColors.warning,
            ),
            data: (metrics) => GestureDetector(
              onTap: () => {},
              child: _buildStatCard(
                'Pending',
                '${metrics.pending}',
                Icons.hourglass_bottom_rounded,
                AppColors.warning,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: noticeCountAsync.when(
            loading: () => _buildStatCardSkeleton(),
            error: (_, __) => _buildStatCard(
              'Notices',
              '0',
              Icons.notifications_rounded,
              AppColors.success,
            ),
            data: (count) => _buildStatCard(
              'Notices',
              '$count',
              Icons.notifications_rounded,
              AppColors.success,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _buildActionCard(
          context,
          title: 'Pending Requests',
          subtitle: 'Review requests',
          icon: Icons.hourglass_bottom_rounded,
          color: AppColors.warning,
          onTap: () => context.go('/official/requests/pending'),
        ),
        _buildActionCard(
          context,
          title: 'Certificates',
          subtitle: 'Filter request records',
          icon: Icons.folder_copy_rounded,
          color: AppColors.info,
          onTap: () => context.go('/admin/certificates'),
        ),
        _buildActionCard(
          context,
          title: 'Manage Users',
          subtitle: 'Search, edit, delete',
          icon: Icons.people_rounded,
          color: AppColors.primary,
          onTap: () => context.go('/admin/users'),
        ),
        _buildActionCard(
          context,
          title: 'Register Official',
          subtitle: 'Add GN Officer',
          icon: Icons.badge_rounded,
          color: AppColors.success,
          onTap: () => context.go('/admin/register-official'),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.small.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.small.copyWith(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserManagementActions(BuildContext context) {
    return Column(
      children: [
        _buildFullWidthAction(
          context,
          title: 'Search & Manage Users',
          subtitle: 'Find users by NIC, phone, or name',
          icon: Icons.search_rounded,
          color: AppColors.primary,
          onTap: () => context.go('/admin/users'),
        ),
        const SizedBox(height: 12),
        _buildFullWidthAction(
          context,
          title: 'Add New User',
          subtitle: 'Create citizen or resident admin account',
          icon: Icons.person_add_alt_rounded,
          color: AppColors.info,
          onTap: () => context.go('/admin/create-user'),
        ),
        const SizedBox(height: 12),
        _buildFullWidthAction(
          context,
          title: 'Register New GN Officer',
          subtitle: 'Create government official account',
          icon: Icons.person_add_rounded,
          color: AppColors.success,
          onTap: () => context.go('/admin/register-official'),
        ),
      ],
    );
  }

  Widget _buildManagementBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.14),
            AppColors.info.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.dashboard_customize_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Control Center',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create users, manage roles, review certificates, and keep the system organized.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthAction(
    BuildContext context, {
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.small.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.small.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: AppColors.info,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Status',
                      style: AppTextStyles.small.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All systems operational',
                      style: AppTextStyles.small.copyWith(
                        fontSize: 11,
                        color: AppColors.info.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Firebase Firestore • Real-time sync enabled',
                    style: AppTextStyles.small.copyWith(
                      fontSize: 10,
                      color: AppColors.textPrimary,
                    ),
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
