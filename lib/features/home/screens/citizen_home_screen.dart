import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/vc_copy.dart';
import '../../../core/models/request_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../documents/repositories/document_repository.dart';

class CitizenHomeScreen extends ConsumerWidget {
  const CitizenHomeScreen({super.key});

  bool _isOffline(List<ConnectivityResult>? results) {
    if (results == null || results.isEmpty) return false;
    return results.every((result) => result == ConnectivityResult.none);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = FirebaseAuth.instance.currentUser;
    final userService = ref.read(userServiceProvider);
    final copy = VcCopy.of(context);

    return FutureBuilder<UserModel?>(
      future: authUser == null
          ? Future.value(null)
          : userService.getUserProfileOnce(authUser.uid),
      builder: (context, profileSnap) {
        final profile = profileSnap.data;
        return StreamBuilder<List<ConnectivityResult>>(
          stream: Connectivity().onConnectivityChanged,
          builder: (context, connectivitySnap) {
            final isOffline = _isOffline(connectivitySnap.data);
            final requests = ref.watch(userRequestsProvider);
            final unreadCount = ref.watch(unreadNotificationCountProvider);

            return Scaffold(
              backgroundColor: AppColors.surfaceParchment,
              appBar: AppBar(
                title: Text(_greeting(copy)),
                actions: [
                  IconButton(
                    onPressed: () => context.push('/notifications'),
                    tooltip: copy.t('notices'),
                    icon: Badge.count(
                      count: unreadCount,
                      isLabelVisible: unreadCount > 0,
                      child: const Icon(Icons.notifications_outlined),
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/profile'),
                    tooltip: copy.t('profile'),
                    icon: const Icon(Icons.person_outline),
                  ),
                ],
              ),
              body: Column(
                children: [
                  if (isOffline) const _OfflineBanner(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(userRequestsProvider),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        children: [
                          _HeroCard(
                            name:
                                profile?.fullName ??
                                authUser?.displayName ??
                                copy.t('home'),
                            village: profile?.village ?? 'Welivita South',
                            requests: requests,
                            copy: copy,
                          ),
                          const SizedBox(height: 24),
                          _SectionTitle(title: copy.t('quickServices')),
                          const SizedBox(height: 12),
                          _QuickGrid(copy: copy),
                          const SizedBox(height: 24),
                          _EmergencyButton(copy: copy),
                          const SizedBox(height: 24),
                          _LatestRequestCard(requests: requests, copy: copy),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _greeting(VcCopy copy) {
    final hour = DateTime.now().hour;
    if (hour < 12) return copy.t('goodMorning');
    if (hour < 17) return copy.t('goodAfternoon');
    return copy.t('goodEvening');
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.name,
    required this.village,
    required this.requests,
    required this.copy,
  });

  final String name;
  final String village;
  final AsyncValue<List<RequestModel>> requests;
  final VcCopy copy;

  @override
  Widget build(BuildContext context) {
    final activeCount = requests.maybeWhen(
      data: (items) => items
          .where(
            (request) =>
                request.status != 'Approved' && request.status != 'Rejected',
          )
          .length,
      orElse: () => 0,
    );

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
            name,
            style: AppTextStyles.displayLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$village · ${copy.t('gnDivision')}',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  '$activeCount ${copy.t('activeRequests')}',
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickGrid extends StatelessWidget {
  const _QuickGrid({required this.copy});

  final VcCopy copy;

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickAction(copy.t('noticeBoard'), Icons.campaign_outlined, () {
        context.push('/notices');
      }),
      _QuickAction(copy.t('lostFound'), Icons.search_outlined, () {
        context.push('/community');
      }),
      _QuickAction(
        copy.t('requestCertificate'),
        Icons.description_outlined,
        () {
          context.push('/applications');
        },
      ),
      _QuickAction(copy.t('jobs'), Icons.work_outline, () {
        context.push('/community');
      }),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.18,
      ),
      itemBuilder: (context, index) => _QuickTile(action: items[index]),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceIvory,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceWarmSand),
            boxShadow: AppColors.shadowLow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.brandGreenSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, color: AppColors.brandGreen, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({required this.copy});

  final VcCopy copy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => context.push('/emergency/alert'),
        style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
        icon: const Icon(Icons.warning_amber_outlined),
        label: Text(copy.t('emergency')),
      ),
    );
  }
}

class _LatestRequestCard extends StatelessWidget {
  const _LatestRequestCard({required this.requests, required this.copy});

  final AsyncValue<List<RequestModel>> requests;
  final VcCopy copy;

  @override
  Widget build(BuildContext context) {
    return requests.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        final latest = items.isEmpty ? null : items.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: copy.t('latestRequest')),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.surfaceIvory,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.surfaceWarmSand),
                ),
                borderRadius: BorderRadius.all(Radius.circular(12)),
                boxShadow: AppColors.shadowLow,
              ),
              child: latest == null
                  ? Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          color: AppColors.brandGreen,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                copy.t('noRequests'),
                                style: AppTextStyles.label,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                copy.t('submitFirst'),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                latest.documentType,
                                style: AppTextStyles.label,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat.yMMMd().format(latest.submittedAt),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(status: latest.status),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = normalized.contains('approved')
        ? AppColors.statusApproved
        : normalized.contains('reject')
        ? AppColors.statusRejected
        : normalized.contains('review')
        ? AppColors.statusReview
        : AppColors.statusPending;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: AppTextStyles.captionMedium.copyWith(color: color),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.overline.copyWith(color: AppColors.inkLight),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warningLight,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        'Offline mode',
        textAlign: TextAlign.center,
        style: AppTextStyles.captionMedium.copyWith(color: AppColors.warning),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}
