import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controllers/admin_controller.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final today = DateFormat('EEE, MMM d').format(DateTime.now());

    Future<void> signOut() async {
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) context.go('/auth/login');
    }

    return Scaffold(
      backgroundColor: AppColors.surfaceParchment,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            onPressed: () => context.push('/profile'),
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            onPressed: signOut,
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _AdminHero(today: today),
            const SizedBox(height: 20),
            _MetricsGrid(statsAsync: statsAsync),
            const SizedBox(height: 24),
            const _SectionLabel('Registration Workflow'),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.badge_outlined,
              title: 'Register GN Officer',
              subtitle:
                  'Create an official account with temporary first-login credentials.',
              buttonLabel: 'Register official',
              onTap: () => context.go('/admin/register-official'),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.person_add_alt_outlined,
              title: 'Register Citizen / User',
              subtitle:
                  'Create citizen accounts or admin-assigned users with pending first login.',
              buttonLabel: 'Register user',
              onTap: () => context.go('/admin/create-user'),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Governance Workflow'),
            const SizedBox(height: 10),
            _WorkflowTile(
              icon: Icons.manage_accounts_outlined,
              title: 'Manage Users & Capabilities',
              subtitle:
                  'Search by NIC, update account status, roles, and committee capabilities.',
              onTap: () => context.go('/admin/users'),
            ),
            const SizedBox(height: 10),
            _WorkflowTile(
              icon: Icons.fact_check_outlined,
              title: 'Certificate Oversight',
              subtitle:
                  'Audit pending and reviewed certificate requests across the system.',
              onTap: () => context.go('/admin/certificates'),
            ),
            const SizedBox(height: 10),
            _WorkflowTile(
              icon: Icons.analytics_outlined,
              title: 'Analytics Review',
              subtitle: 'View aggregate stats from system_stats/global.',
              onTap: () => context.go('/admin/analytics'),
            ),
            const SizedBox(height: 10),
            _WorkflowTile(
              icon: Icons.history_rounded,
              title: 'Audit Logs',
              subtitle:
                  'Monitor recent role, certificate, notice, and incident actions.',
              onTap: () => context.go('/admin/audit-logs'),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: signOut,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorRed,
                side: const BorderSide(color: AppColors.errorRed),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _AdminBottomBar(context: context),
    );
  }
}

class _AdminHero extends StatelessWidget {
  const _AdminHero({required this.today});

  final String today;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Administration',
            style: AppTextStyles.displayLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'GN onboarding, user permissions, certificate oversight, and audit-ready operations.',
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 18),
          _HeroChip(icon: Icons.calendar_today_outlined, label: today),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.statsAsync});

  final AsyncValue<Map<String, int>> statsAsync;

  @override
  Widget build(BuildContext context) {
    if (statsAsync.isLoading && !statsAsync.hasValue) {
      return const _MetricsLoadingGrid();
    }

    if (statsAsync.hasError && !statsAsync.hasValue) {
      return _MetricsError(error: statsAsync.error);
    }

    final stats = statsAsync.value ?? const <String, int>{};
    final totalUsers = stats['totalUsers'] == 0
        ? (stats['totalCitizens'] ?? 0) +
              (stats['totalGnOfficers'] ?? 0) +
              (stats['totalCommitteeMembers'] ?? 0)
        : stats['totalUsers'] ?? 0;
    final pendingRequests = stats['pendingRequests'] ?? 0;
    final totalRequests = stats['totalRequests'] ?? 0;
    final notices = stats['publishedNotices'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        _MetricCard(
          title: 'Users',
          value: '$totalUsers',
          icon: Icons.group_outlined,
          color: AppColors.brandGreen,
        ),
        _MetricCard(
          title: 'Pending',
          value: '$pendingRequests',
          icon: Icons.pending_actions_outlined,
          color: AppColors.statusPending,
        ),
        _MetricCard(
          title: 'Requests',
          value: '$totalRequests',
          icon: Icons.description_outlined,
          color: AppColors.statusReview,
        ),
        _MetricCard(
          title: 'Notices',
          value: '$notices',
          icon: Icons.campaign_outlined,
          color: AppColors.statusApproved,
        ),
      ],
    );
  }
}

class _MetricsLoadingGrid extends StatelessWidget {
  const _MetricsLoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: const [
        _MetricCard(
          title: 'Users',
          value: '...',
          icon: Icons.group_outlined,
          color: AppColors.brandGreen,
        ),
        _MetricCard(
          title: 'Pending',
          value: '...',
          icon: Icons.pending_actions_outlined,
          color: AppColors.statusPending,
        ),
        _MetricCard(
          title: 'Requests',
          value: '...',
          icon: Icons.description_outlined,
          color: AppColors.statusReview,
        ),
        _MetricCard(
          title: 'Notices',
          value: '...',
          icon: Icons.campaign_outlined,
          color: AppColors.statusApproved,
        ),
      ],
    );
  }
}

class _MetricsError extends StatelessWidget {
  const _MetricsError({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceIvory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorRed),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.errorRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Unable to load dashboard data: $error',
              style: AppTextStyles.caption.copyWith(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

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
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(value, style: AppTextStyles.h2),
          const SizedBox(height: 2),
          Text(title, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

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
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.brandGreenSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.brandGreen),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: AppTextStyles.h3)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: AppTextStyles.body.copyWith(color: AppColors.inkMid),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowTile extends StatelessWidget {
  const _WorkflowTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceIvory,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceWarmSand),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.brandGreen, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodySemiBold),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

class _AdminBottomBar extends StatelessWidget {
  const _AdminBottomBar({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.surfaceWarmSand)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _BottomItem(
                icon: Icons.dashboard_outlined,
                label: 'Desk',
                active: true,
                onTap: () => context.go('/admin/dashboard'),
              ),
              _BottomItem(
                icon: Icons.badge_outlined,
                label: 'GN',
                onTap: () => context.go('/admin/register-official'),
              ),
              _BottomItem(
                icon: Icons.group_outlined,
                label: 'Users',
                onTap: () => context.go('/admin/users'),
              ),
              _BottomItem(
                icon: Icons.description_outlined,
                label: 'Audit',
                onTap: () => context.go('/admin/audit-logs'),
              ),
              _BottomItem(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () => context.push('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? AppColors.brandGreen : AppColors.inkLight,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: (active ? AppTextStyles.tab : AppTextStyles.tabInactive),
            ),
          ],
        ),
      ),
    );
  }
}
