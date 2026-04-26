import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/models/request_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CitizenHomeScreen extends ConsumerStatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  ConsumerState<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends ConsumerState<CitizenHomeScreen> {
  bool _isOffline(List<ConnectivityResult>? results) {
    if (results == null || results.isEmpty) return false;
    return results.every((r) => r == ConnectivityResult.none);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userService = ref.read(userServiceProvider);

    return FutureBuilder<UserModel?>(
      future: user == null
          ? Future.value(null)
          : userService.getUserProfileOnce(user.uid),
      builder: (context, profileSnap) {
        final profile = profileSnap.data;
        return StreamBuilder<List<ConnectivityResult>>(
          stream: Connectivity().onConnectivityChanged,
          builder: (context, connectivitySnap) {
            final isOffline = _isOffline(connectivitySnap.data);
            final l = context.l10n;
            final unreadCount = ref.watch(unreadNotificationCountProvider);
            return Scaffold(
              backgroundColor: AppColors.background,
              body: Column(
                children: [
                  if (isOffline)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 4,
                        bottom: 8,
                        left: 16,
                        right: 16,
                      ),
                      color: AppColors.warning,
                      child: SafeArea(
                        bottom: false,
                        top: false,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l.offlineBanner,
                              style: AppTextStyles.small.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroGreeting(
                            context,
                            user,
                            profile,
                            isOffline,
                            unreadCount,
                          ),
                          const SizedBox(height: 24),
                          _buildEmergencyButton(context),
                          const SizedBox(height: 24),
                          _buildHouseholdSection(context, user, l),
                          const SizedBox(height: 32),
                          _buildSecondaryActions(context, l, unreadCount),
                          const SizedBox(height: 32),
                          _buildRecentActivity(context, const AsyncData([]), l),
                          const SizedBox(height: 48),
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

  // ── Hero Greeting ─────────────────────────────────────────────────────
  Widget _buildHeroGreeting(
    BuildContext context,
    User? user,
    UserModel? profile,
    bool isOffline,
    int unreadCount,
  ) {
    final l = context.l10n;
    final topPadding = isOffline ? 0.0 : MediaQuery.of(context).padding.top;
    final displayName = profile?.fullName ?? user?.displayName ?? l.citizen;
    final village = profile?.village ?? 'Welivita South';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topPadding + 20, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.primary,
        image: const DecorationImage(
          image: AssetImage('assets/images/hero_bg.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
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
                      'Good Morning,',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName,
                      style: AppTextStyles.displayLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Hero(
                  tag: 'profile_avatar',
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 2,
                          ),
                          image: DecorationImage(
                            image: user?.photoURL != null
                                ? NetworkImage(user!.photoURL!) as ImageProvider
                                : const AssetImage(
                                    'assets/images/default_avatar.jpg',
                                  ),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: unreadCount > 9
                                ? const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  )
                                : const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: unreadCount > 9
                                  ? BoxShape.rectangle
                                  : BoxShape.circle,
                              borderRadius: unreadCount > 9
                                  ? BorderRadius.circular(10)
                                  : null,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: AppTextStyles.small.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: unreadCount > 9 ? 10 : 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$village • GN 521',
                      style: AppTextStyles.small.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Emergency Button ──────────────────────────────────────────────────
  Widget _buildEmergencyButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () => context.push('/emergency/alert'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: AppColors.error.withOpacity(0.4),
          ),
          icon: const Icon(Icons.sos_rounded, size: 28),
          label: const Text(
            'SOS / EMERGENCY REPORT',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  // ── Secondary Actions ─────────────────────────────────────────────────
  Widget _buildSecondaryActions(
    BuildContext context,
    dynamic l,
    int unreadCount,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.services,
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSecondaryItem(
                  icon: Icons.description_rounded,
                  title: 'Request Certificate',
                  subtitle: 'Fill and submit certificate forms',
                  color: AppColors.success,
                  onTap: () => context.push('/applications'),
                  isFirst: true,
                ),
                const Divider(height: 1, indent: 72, color: AppColors.divider),
                _buildSecondaryItem(
                  icon: Icons.track_changes_rounded,
                  title: l.trackApplication,
                  subtitle: l.viewStatusOfRequests,
                  color: AppColors.info,
                  onTap: () => context.push('/documents/tracking'),
                ),
                const Divider(height: 1, indent: 72, color: AppColors.divider),
                _buildSecondaryItem(
                  icon: Icons.notifications_active_rounded,
                  title: l.homeAlertsAndUpdates,
                  subtitle: unreadCount > 0
                      ? l.homeNotificationsSubtitleUnread(unreadCount)
                      : l.homeNotificationsSubtitle,
                  color: AppColors.warning,
                  onTap: () => context.push('/notifications'),
                  showUnreadIndicator: unreadCount > 0,
                  unreadCount: unreadCount,
                ),
                const Divider(height: 1, indent: 72, color: AppColors.divider),
                _buildSecondaryItem(
                  icon: Icons.people_alt_rounded,
                  title: l.communityFeed,
                  subtitle: 'Lost & Found, Local Jobs',
                  color: AppColors.accentPurple,
                  onTap: () => context.push('/community'),
                ),
                const Divider(height: 1, indent: 72, color: AppColors.divider),
                _buildSecondaryItem(
                  icon: Icons.notifications_active_rounded,
                  title: l.noticeBoard,
                  subtitle: l.officialAnnouncements,
                  color: AppColors.primary,
                  onTap: () => context.push('/notices'),
                ),
                const Divider(height: 1, indent: 72, color: AppColors.divider),
                _buildSecondaryItem(
                  icon: Icons.support_agent_rounded,
                  title: 'Help & Support',
                  subtitle: 'FAQs and contact info',
                  color: AppColors.success,
                  onTap: () => context.push('/help'),
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Household / Member Management ─────────────────────────────────────
  Widget _buildHouseholdSection(BuildContext context, User? user, dynamic l) {
    if (user == null) return const SizedBox.shrink();
    final userService = ref.read(userServiceProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.householdManagement,
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FutureBuilder<bool>(
              future: userService.isAdmin(user.uid),
              builder: (ctx, snap) {
                final isAdmin = snap.data == true;
                return Column(
                  children: [
                    _buildSecondaryItem(
                      icon: Icons.group_add_rounded,
                      title: 'Add Family Member / Rental',
                      subtitle: l.registerFamilyMember,
                      color: AppColors.primary,
                      onTap: () => context.push('/auth/add-member'),
                      isFirst: true,
                      isLast: !isAdmin,
                    ),
                    if (isAdmin) ...[
                      const Divider(
                        height: 1,
                        indent: 72,
                        color: AppColors.divider,
                      ),
                      _buildSecondaryItem(
                        icon: Icons.person_add_alt_1_rounded,
                        title: l.registerNewResident,
                        subtitle: l.createAccountNewResident,
                        color: AppColors.error,
                        onTap: () => context.push('/auth/create-resident'),
                        isLast: true,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
    bool showUnreadIndicator = false,
    int unreadCount = 0,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(24) : Radius.zero,
          bottom: isLast ? const Radius.circular(24) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (showUnreadIndicator) ...[
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: unreadCount > 9 ? 6 : 5,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  alignment: Alignment.center,
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: AppTextStyles.small.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: unreadCount > 9 ? 10 : 11,
                    ),
                  ),
                ),
              ],
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Recent Activity ───────────────────────────────────────────────────
  Widget _buildRecentActivity(
    BuildContext context,
    AsyncValue<List<RequestModel>> requestsValue,
    dynamic l,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.recentActivity,
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
              ),
              GestureDetector(
                onTap: () => context.push('/documents/tracking'),
                child: Text(
                  l.viewAll,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: requestsValue.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        l.noRecentActivity,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }
                final recentRequests = requests.take(3).toList();
                return Column(
                  children: [
                    for (int i = 0; i < recentRequests.length; i++)
                      Column(
                        children: [
                          _buildActivityItem(
                            title: recentRequests[i].documentType,
                            status: _localizedStatus(
                              recentRequests[i].status,
                              l,
                            ),
                            statusColor: _getStatusColor(
                              recentRequests[i].status,
                            ),
                            date: DateFormat.yMMMd().format(
                              recentRequests[i].submittedAt,
                            ),
                            icon: _getStatusIcon(recentRequests[i].status),
                            isFirst: i == 0,
                            isLast: i == recentRequests.length - 1,
                          ),
                          if (i < recentRequests.length - 1)
                            const Divider(
                              height: 1,
                              indent: 64,
                              color: AppColors.divider,
                            ),
                        ],
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Error loading activity')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _localizedStatus(String status, dynamic l) {
    switch (status) {
      case 'Approved':
        return l.approved;
      case 'Pending':
        return l.pending;
      case 'In Review':
        return l.inReview;
      case 'Rejected':
        return l.rejected;
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppColors.success;
      case 'Pending':
        return AppColors.warning;
      case 'In Review':
        return AppColors.info;
      case 'Rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Approved':
        return Icons.check_circle_rounded;
      case 'Pending':
        return Icons.access_time_filled_rounded;
      case 'In Review':
        return Icons.rate_review_rounded;
      case 'Rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  Widget _buildActivityItem({
    required String title,
    required String status,
    required Color statusColor,
    required String date,
    required IconData icon,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: AppTextStyles.small.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
