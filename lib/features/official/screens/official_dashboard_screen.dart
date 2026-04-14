import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/dashboard_metrics.dart';
import '../../../core/models/request_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import '../repositories/official_repository.dart';

final officialQueuePreviewProvider = StreamProvider<List<RequestModel>>((ref) {
  return ref.watch(officialRepositoryProvider).getPendingRequests();
});

class OfficialDashboardScreen extends ConsumerWidget {
  const OfficialDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final queueAsync = ref.watch(officialQueuePreviewProvider);
    final authService = ref.watch(authServiceProvider);
    final currentUser = authService.currentUser;
    final officerName = currentUser?.displayName?.trim().isNotEmpty == true
        ? currentUser!.displayName!
        : (currentUser?.email ?? 'GN Officer');
    final dayLabel = DateFormat('EEEE').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _buildBottomNav(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardMetricsProvider);
            ref.invalidate(officialQueuePreviewProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  child: _buildTopBar(
                    officerName: officerName,
                    onNotificationsTap: () => context.push('/notifications'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 2, 22, 0),
                  child: _buildWelcome(dayLabel),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildPendingHeader(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: queueAsync.when(
                    data: (items) => _buildPendingList(
                      context,
                      items.take(3).toList(),
                    ),
                    loading: _buildLoadingList,
                    error: (_, __) => _buildQueueError(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: metricsAsync.when(
                    data: (metrics) => _buildServiceMetrics(metrics),
                    loading: () => _buildMetricSkeleton(),
                    error: (_, __) => _buildMetricError(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: _buildNoticeComposer(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
                  child: _buildCommunityPulseHeader(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: _buildCommunityPulse(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar({
    required String officerName,
    required VoidCallback onNotificationsTap,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceGrey,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.person, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'VillageConnect',
            style: AppTextStyles.h3.copyWith(
              color: const Color(0xFF0E3E19),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: onNotificationsTap,
          icon: const Icon(Icons.notifications_rounded, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildWelcome(String dayLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sector 124-B Admin',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Grama Niladhari',
          style: AppTextStyles.h1.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          '$dayLabel • Live request command desk',
          style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPendingHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Pending Requests',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'LIVE',
            style: AppTextStyles.small.copyWith(
              color: AppColors.info,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingList(BuildContext context, List<RequestModel> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
        ),
        child: Text(
          'no pending request',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: items
          .map(
            (request) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(
                    left: BorderSide(
                      color: AppColors.primary,
                      width: 3,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.fullName,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                request.documentType,
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _timeAgo(request.submittedAt),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context.push(
                              '/official/requests/${request.id}/review',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Review'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => context.go('/official/requests/pending'),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surfaceGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.more_horiz_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLoadingList() {
    return Container(
      height: 90,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildQueueError() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Failed to load queue. Pull to refresh.',
        style: AppTextStyles.body.copyWith(color: AppColors.error),
      ),
    );
  }

  Widget _buildServiceMetrics(DashboardMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Snapshot',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metricPill(
                icon: Icons.pending_actions_rounded,
                title: 'Pending',
                value: '${metrics.totalPending}',
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricPill(
                icon: Icons.check_circle_rounded,
                title: 'Approved',
                value: '${metrics.approvedThisMonth}',
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricPill({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            title,
            style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSkeleton() {
    return Container(
      height: 98,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildNoticeComposer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Post Notice',
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            readOnly: true,
            onTap: () => context.go('/notices'),
            decoration: const InputDecoration(hintText: 'Notice Title'),
          ),
          const SizedBox(height: 10),
          TextField(
            readOnly: true,
            onTap: () => context.go('/notices'),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Provide details for the community...',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/notices'),
              icon: const Icon(Icons.send_rounded),
              label: const Text('POST NOTICE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityPulseHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Community Pulse',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        TextButton(
          onPressed: () => context.go('/community'),
          child: const Text('View All'),
        ),
      ],
    );
  }

  Widget _buildCommunityPulse(BuildContext context) {
    return Column(
      children: [
        _communityPostCard(
          author: 'Kamani Jayasuriya',
          message: 'Organizing a cleaning session for the main road this Sunday. Who\'s in?',
          time: 'Just now',
          onApprove: () => context.go('/community'),
          onRemove: () => context.go('/community'),
        ),
        const SizedBox(height: 12),
        _communityPostCard(
          author: 'Mr. Samarakoon',
          message: 'Found a set of keys near the temple. Please contact if they are yours.',
          time: '15m ago',
          onApprove: () => context.go('/community'),
          onRemove: () => context.go('/community'),
        ),
      ],
    );
  }

  Widget _communityPostCard({
    required String author,
    required String message,
    required String time,
    required VoidCallback onApprove,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceGrey,
                ),
                child: const Icon(Icons.person, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  author,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                time,
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successLight,
                    foregroundColor: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_rounded, size: 16),
                  label: const Text('Remove'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.94),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              active: true,
              onTap: () => context.go('/official/dashboard'),
            ),
            _navItem(
              icon: Icons.folder_shared_rounded,
              label: 'Requests',
              onTap: () => context.go('/official/requests/pending'),
            ),
            _navItem(
              icon: Icons.campaign_rounded,
              label: 'Notices',
              onTap: () => context.go('/notices'),
            ),
            _navItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              onTap: () => context.push('/profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    bool active = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: active ? AppColors.primary : AppColors.textMuted),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: active ? AppColors.primary : AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
      ),
      child: Text(
        'Failed to load request metrics. Pull to refresh.',
        style: AppTextStyles.body.copyWith(color: AppColors.error),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
