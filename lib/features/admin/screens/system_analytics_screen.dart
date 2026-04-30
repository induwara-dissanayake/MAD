import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controllers/admin_controller.dart';

class SystemAnalyticsScreen extends ConsumerWidget {
  const SystemAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceParchment,
      appBar: AppBar(
        title: const Text('System Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin/dashboard');
            }
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardStatsProvider);
        },
        child: statsAsync.when(
          loading: () => const _AnalyticsLoading(),
          error: (error, stack) => _AnalyticsError(error: error),
          data: (data) => _AnalyticsContent(data: data),
        ),
      ),
    );
  }

  static String _intText(int? value) {
    return (value ?? 0).toString();
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.data});

  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live System Metrics',
                style: AppTextStyles.displaySmall.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Counts update from Firestore collections used by the admin and official workflows.',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.22,
          children: [
            _MetricCard(
              label: 'Total Users',
              value: SystemAnalyticsScreen._intText(data['totalUsers']),
              icon: Icons.group_outlined,
              color: AppColors.brandGreen,
            ),
            _MetricCard(
              label: 'Citizens',
              value: SystemAnalyticsScreen._intText(data['totalCitizens']),
              icon: Icons.people_outline,
              color: AppColors.brandGreen,
            ),
            _MetricCard(
              label: 'GN Officers',
              value: SystemAnalyticsScreen._intText(data['totalGnOfficers']),
              icon: Icons.badge_outlined,
              color: AppColors.statusReview,
            ),
            _MetricCard(
              label: 'Committee',
              value: SystemAnalyticsScreen._intText(
                data['totalCommitteeMembers'],
              ),
              icon: Icons.groups_outlined,
              color: AppColors.info,
            ),
            _MetricCard(
              label: 'Pending Requests',
              value: SystemAnalyticsScreen._intText(data['pendingRequests']),
              icon: Icons.pending_actions_outlined,
              color: AppColors.statusPending,
            ),
            _MetricCard(
              label: 'Total Requests',
              value: SystemAnalyticsScreen._intText(data['totalRequests']),
              icon: Icons.description_outlined,
              color: AppColors.statusReview,
            ),
            _MetricCard(
              label: 'Published Notices',
              value: SystemAnalyticsScreen._intText(data['publishedNotices']),
              icon: Icons.campaign_outlined,
              color: AppColors.statusApproved,
            ),
            _MetricCard(
              label: 'Open Incidents',
              value: SystemAnalyticsScreen._intText(data['openIncidents']),
              icon: Icons.warning_amber_outlined,
              color: AppColors.error,
            ),
            _MetricCard(
              label: 'Pending Posts',
              value: SystemAnalyticsScreen._intText(
                data['pendingCommunityPosts'],
              ),
              icon: Icons.forum_outlined,
              color: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'These metrics are calculated from live admin-readable collections, so they keep working even when system_stats/global is missing or stale.',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

class _AnalyticsLoading extends StatelessWidget {
  const _AnalyticsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: const [
        SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

class _AnalyticsError extends StatelessWidget {
  const _AnalyticsError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceIvory,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.errorRed),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.errorRed,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Unable to load analytics: $error',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.errorRed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
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
          Icon(icon, color: color),
          const Spacer(),
          Text(value, style: AppTextStyles.h2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
