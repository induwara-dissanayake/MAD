import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Urgent',
    'Government',
    'Health',
    'Events',
  ];

  final List<_NotificationItem> _notifications = [
    _NotificationItem(
      title: 'Flood Warning',
      body:
          'Heavy rainfall expected in Kaduwela and surrounding areas. Please take necessary precautions and stay indoors. Emergency hotline: 117.',
      timeAgo: '2 hours ago',
      category: 'Urgent',
      semanticColor: AppColors.error,
      isUnread: true,
    ),
    _NotificationItem(
      title: 'Application Approved',
      body:
          'Your character certificate application (REF: CC-2026-0142) has been approved. Please visit the GN Office to collect your document during office hours.',
      timeAgo: 'Yesterday',
      category: 'Government',
      semanticColor: AppColors.primary,
      isUnread: false,
    ),
    _NotificationItem(
      title: 'Health Camp Tomorrow',
      body:
          'Free health screening at Community Hall from 9 AM to 4 PM. Services include blood pressure, blood sugar, BMI checks, and eye screening. Bring your NIC.',
      timeAgo: '2 days ago',
      category: 'Health',
      semanticColor: AppColors.success,
      isUnread: false,
    ),
    _NotificationItem(
      title: 'Document Ready for Pickup',
      body:
          'Your residence certificate (REF: RC-2026-0088) is ready for collection. Please bring your NIC and original application receipt to the GN Office.',
      timeAgo: '3 days ago',
      category: 'Government',
      semanticColor: AppColors.primary,
      isUnread: false,
    ),
    _NotificationItem(
      title: 'Village Meeting',
      body:
          'Annual village meeting scheduled for March 1 at 3:00 PM at the Community Hall. Agenda includes road development, water supply improvements, and budget review.',
      timeAgo: '1 week ago',
      category: 'Events',
      semanticColor: AppColors.warning,
      isUnread: false,
    ),
    _NotificationItem(
      title: 'Road Closure Notice',
      body:
          'Main road (Kaduwela-Malabe) will be closed from 8 AM to 5 PM on Saturday for drainage improvement work. Please use alternative routes via Athurugiriya Road.',
      timeAgo: '1 week ago',
      category: 'Urgent',
      semanticColor: AppColors.error,
      isUnread: false,
    ),
  ];

  List<_NotificationItem> get _filteredNotifications {
    if (_selectedFilter == 'All') return _notifications;
    return _notifications.where((n) => n.category == _selectedFilter).toList();
  }

  void _markAllRead() {
    setState(() {
      for (final notification in _notifications) {
        notification.isUnread = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildFilterChips(),
            Expanded(child: _buildNotificationsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final unreadCount = _notifications.where((n) => n.isUnread).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications', style: AppTextStyles.h1),
                if (unreadCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '$unreadCount unread',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
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
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                filter,
                style: AppTextStyles.captionMedium.copyWith(
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationsList() {
    final filtered = _filteredNotifications;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceGrey,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 28,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildNotificationCard(filtered[index]),
    );
  }

  Widget _buildNotificationCard(_NotificationItem notification) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showNotificationDetail(notification),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isUnread
                ? AppColors.primaryLight.withOpacity(0.4)
                : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: notification.isUnread
                          ? AppTextStyles.bodySemiBold
                          : AppTextStyles.bodyMedium,
                    ),
                  ),
                  if (notification.isUnread)
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
                notification.body,
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
                      color: notification.semanticColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      notification.category,
                      style: AppTextStyles.small.copyWith(
                        fontWeight: FontWeight.w600,
                        color: notification.semanticColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(notification.timeAgo, style: AppTextStyles.small),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetail(_NotificationItem notification) {
    setState(() => notification.isUnread = false);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: notification.semanticColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          notification.category,
                          style: AppTextStyles.captionMedium.copyWith(
                            color: notification.semanticColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(notification.timeAgo, style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(notification.title, style: AppTextStyles.h2),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),
                  Text(
                    notification.body,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: AppTextStyles.buttonSmall.copyWith(
                          color: AppColors.primary,
                        ),
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
}

class _NotificationItem {
  final String title;
  final String body;
  final String timeAgo;
  final String category;
  final Color semanticColor;
  bool isUnread;

  _NotificationItem({
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.category,
    required this.semanticColor,
    required this.isUnread,
  });
}
