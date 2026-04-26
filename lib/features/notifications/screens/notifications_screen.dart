import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/localization_extensions.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'All';

  static const _filters = [
    'All',
    'Unread',
    'Applications',
    'Community',
    'Complaint',
  ];

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final authService = ref.watch(authServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.notifications,
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final userId = authService.currentUser?.uid;
              if (userId == null) return;
              await ref.read(notificationServiceProvider).markAllAsRead(userId);
            },
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark all read',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          final filtered = _filterNotifications(notifications);
          final unreadCount = notifications.where((n) => !n.isRead).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Updates', style: AppTextStyles.h1),
                          const SizedBox(height: 4),
                          Text(
                            unreadCount > 0
                                ? '$unreadCount unread'
                                : 'All caught up',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          filter,
                          style: AppTextStyles.captionMedium.copyWith(
                            color: isSelected
                                ? AppColors.textOnPrimary
                                : AppColors.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _buildNotificationCard(filtered[index]);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Failed to load notifications: $error'),
        ),
      ),
    );
  }

  List<NotificationModel> _filterNotifications(
    List<NotificationModel> notifications,
  ) {
    bool isApplicationType(String t) =>
        t == 'approval' || t == 'rejection' || t == 'info_request';

    switch (_selectedFilter) {
      case 'Unread':
        return notifications.where((n) => !n.isRead).toList();
      case 'Applications':
        return notifications.where((n) => isApplicationType(n.type)).toList();
      case 'Community':
        return notifications
            .where((n) => n.type == 'community_important')
            .toList();
      case 'Complaint':
        return notifications
            .where((n) => n.type == 'complaint_update')
            .toList();
      default:
        return notifications;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.surfaceGrey,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 32,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              context.l10n.notificationsEmptyBody,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onNotificationTap(NotificationModel notification) async {
    if (!notification.isRead) {
      await ref.read(notificationServiceProvider).markAsRead(notification.id);
    }
    if (!mounted) return;

    final opened = _tryNavigateFromNotification(context, notification);
    if (opened) return;

    final semanticColor = _colorForType(notification.type);
    final timestamp =
        DateFormat('MMM d, yyyy • h:mm a').format(notification.createdAt);
    if (!mounted) return;
    _showNotificationDetail(notification, timestamp, semanticColor);
  }

  /// Returns true if a route was pushed (detail sheet is skipped).
  bool _tryNavigateFromNotification(
    BuildContext context,
    NotificationModel n,
  ) {
    final route = n.actionRoute;
    final extra = n.actionExtra;

    if (route == '/documents/detail') {
      final trackingId = extra['trackingId'] as String? ?? n.requestId ?? '';
      if (trackingId.isEmpty) return false;
      final documentType = extra['documentType'] as String? ?? '';
      final status = extra['status'] as String? ?? '';
      context.push(
        '/documents/detail',
        extra: {
          'trackingId': trackingId,
          'documentType': documentType,
          'status': status,
        },
      );
      return true;
    }

    if (route == '/community/chat') {
      final room = extra['roomName'] as String? ?? 'Community Chat';
      context.push('/community/chat', extra: <String, dynamic>{'name': room});
      return true;
    }

    if (n.type == 'complaint_update' || (route == '/community' && n.relatedId != null)) {
      context.push('/community');
      return true;
    }

    if (n.requestId != null && n.requestId!.isNotEmpty) {
      final documentType = extra['documentType'] as String? ?? '';
      final status = extra['status'] as String? ?? '';
      context.push(
        '/documents/detail',
        extra: {
          'trackingId': n.requestId!,
          'documentType': documentType,
          'status': status,
        },
      );
      return true;
    }

    return false;
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final semanticColor = _colorForType(notification.type);
    final timestamp =
        DateFormat('MMM d, yyyy • h:mm a').format(notification.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? AppColors.card
                : AppColors.primaryLight.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? AppColors.border.withValues(alpha: 0.45)
                  : semanticColor.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: semanticColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForType(notification.type),
                  color: semanticColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: notification.isRead
                                ? AppTextStyles.bodyMedium
                                : AppTextStyles.bodySemiBold,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 6, left: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: semanticColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _labelForType(notification.type),
                            style: AppTextStyles.small.copyWith(
                              fontWeight: FontWeight.w600,
                              color: semanticColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(timestamp, style: AppTextStyles.small),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetail(
    NotificationModel notification,
    String timestamp,
    Color semanticColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.disabled,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: semanticColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _labelForType(notification.type),
                      style: AppTextStyles.captionMedium
                          .copyWith(color: semanticColor),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    notification.isRead
                        ? Icons.mark_email_read_rounded
                        : Icons.mark_email_unread_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(timestamp, style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 16),
              Text(notification.title, style: AppTextStyles.h2),
              const SizedBox(height: 16),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 16),
              Text(
                notification.message,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: AppTextStyles.button
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'approval':
        return AppColors.success;
      case 'rejection':
        return AppColors.error;
      case 'info_request':
        return AppColors.warning;
      case 'complaint_update':
        return AppColors.info;
      case 'community_important':
        return AppColors.accentPurple;
      case 'notice':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'approval':
        return Icons.check_circle_rounded;
      case 'rejection':
        return Icons.cancel_rounded;
      case 'info_request':
        return Icons.info_rounded;
      case 'complaint_update':
        return Icons.flag_rounded;
      case 'community_important':
        return Icons.campaign_rounded;
      case 'notice':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'approval':
        return 'Approved';
      case 'rejection':
        return 'Rejected';
      case 'info_request':
        return 'Info needed';
      case 'complaint_update':
        return 'Complaint';
      case 'community_important':
        return 'Community';
      case 'notice':
        return 'Notice';
      default:
        return 'Update';
    }
  }
}
