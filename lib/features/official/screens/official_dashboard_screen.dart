import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class OfficialDashboardScreen extends StatefulWidget {
  const OfficialDashboardScreen({super.key});

  @override
  State<OfficialDashboardScreen> createState() =>
      _OfficialDashboardScreenState();
}

class _OfficialDashboardScreenState extends State<OfficialDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, bool> _expandedCategories = {
    'Document Review': true,
    'Community Management': false,
    'User Management': false,
    'System Admin': false,
  };

  final List<_StatCard> _stats = [
    _StatCard('Pending', '12', AppColors.accentYellow, AppColors.warning),
    _StatCard('In Review', '5', AppColors.accentBlue, AppColors.info),
    _StatCard('Approved Today', '8', AppColors.accentGreen, AppColors.success),
    _StatCard('Rejected', '2', AppColors.accentRed, AppColors.error),
  ];

  final List<_PendingRequest> _recentRequests = [
    _PendingRequest(
      citizenName: 'Nadeeka Silva',
      documentType: 'Character Certificate',
      submittedDate: '22 Feb 2026',
      initials: 'NS',
    ),
    _PendingRequest(
      citizenName: 'Ruwan Jayasinghe',
      documentType: 'Residence Certificate',
      submittedDate: '21 Feb 2026',
      initials: 'RJ',
    ),
    _PendingRequest(
      citizenName: 'Malini Kumari',
      documentType: 'Income Certificate',
      submittedDate: '20 Feb 2026',
      initials: 'MK',
    ),
  ];

  final List<_Incident> _incidents = [
    _Incident(
      title: 'Fallen Tree Blocking Road',
      location: 'Main St, Kaduwela',
      date: 'Today, 10:30 AM',
      priority: 'High',
      priorityColor: AppColors.error,
    ),
    _Incident(
      title: 'Water Pipe Burst',
      location: 'Temple Road',
      date: 'Yesterday, 4:15 PM',
      priority: 'Medium',
      priorityColor: AppColors.warning,
    ),
    _Incident(
      title: 'Street Lamp Malfunction',
      location: '2nd Lane, Malabe',
      date: '20 Feb 2026',
      priority: 'Low',
      priorityColor: AppColors.success,
    ),
    _Incident(
      title: 'Garbage Collection Issue',
      location: 'Housing Scheme',
      date: '19 Feb 2026',
      priority: 'Medium',
      priorityColor: AppColors.warning,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBarArea(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Overview
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildStatsRow(),
                          const SizedBox(height: 28),
                          _buildQuickActions(),
                          const SizedBox(height: 28),
                          _buildRecentPendingRequests(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  // Tab 2: Incidents
                  _buildIncidentDashboard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textOnPrimary.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nimal Fernando',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/official/profile'),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.textOnPrimary.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.textOnPrimary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.textOnPrimary.withOpacity(0.9),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.textOnPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.textOnPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textOnPrimary.withOpacity(0.7),
              labelStyle: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Incidents'),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _stats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final stat = _stats[index];
          return Container(
            width: 150,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: stat.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: stat.textColor.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: stat.textColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      _getStatIcon(index),
                      size: 18,
                      color: stat.textColor,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.count,
                      style: AppTextStyles.h1.copyWith(
                        color: stat.textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stat.label,
                      style: AppTextStyles.small.copyWith(
                        color: stat.textColor.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getStatIcon(int index) {
    switch (index) {
      case 0:
        return Icons.schedule_outlined;
      case 1:
        return Icons.preview_outlined;
      case 2:
        return Icons.check_circle_outline;
      case 3:
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildQuickActions() {
    final actionCategories = {
      'Document Review': [
        ('Review Requests', Icons.rate_review_outlined, AppColors.primaryLight, '/official/pending'),
        ('Manage Notices', Icons.article_outlined, AppColors.infoLight, '/official/notices'),
        ('Registered Users', Icons.people_alt_rounded, AppColors.primaryLight, '/official/registered-users'),
      ],
      'Community Management': [
        ('Post Notice', Icons.campaign_outlined, AppColors.warningLight, '/official/post-notice'),
        ('Broadcast Message', Icons.cell_tower_rounded, AppColors.infoLight, '/official/broadcast'),
        ('Community Moderation', Icons.how_to_reg_outlined, AppColors.warningLight, '/official/moderation'),
        ('Committee Tasks', Icons.task_alt_rounded, AppColors.successLight, '/committee/tasks'),
        ('Community Polls', Icons.poll_rounded, AppColors.primaryLight, '/committee/polls'),
      ],
      'User Management': [
        ('Register Citizen', Icons.person_add_outlined, AppColors.successLight, '/auth/create-resident'),
        ('Register Committee Member', Icons.group_add_rounded, AppColors.infoLight, '/auth/add-member'),
      ],
      'System Admin': [
        ('Incident Dashboard', Icons.report_rounded, AppColors.errorLight, '/incidents'),
        ('Admin Panel', Icons.admin_panel_settings_rounded, Color(0xFFF3E5F5), '/admin/dashboard'),
      ],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Access', style: AppTextStyles.h3),
        const SizedBox(height: 14),
        ...actionCategories.entries.map((entry) {
          final category = entry.key;
          final actions = entry.value;
          final isExpanded = _expandedCategories[category] ?? false;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _expandedCategories[category] = !isExpanded;
                        });
                      },
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              category,
                              style: AppTextStyles.bodySemiBold,
                            ),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.secondarySurface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  isExpanded
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isExpanded)
                    Column(
                      children: [
                        Container(
                          height: 1,
                          color: AppColors.border,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: GridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.0,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: actions.map((action) {
                              return _buildCategoryActionTile(
                                title: action.$1,
                                icon: action.$2,
                                backgroundColor: action.$3,
                                onTap: () => context.push(action.$4),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCategoryActionTile({
    required String title,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 4,
                offset: const Offset(0, 1),
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
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPendingRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Pending Requests', style: AppTextStyles.h3),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  context.push('/official/pending');
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'View All',
                        style: AppTextStyles.captionMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(_recentRequests.length, (index) {
          final request = _recentRequests[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < _recentRequests.length - 1 ? 10 : 0,
            ),
            child: _buildRequestCard(request),
          );
        }),
      ],
    );
  }

  Widget _buildRequestCard(_PendingRequest request) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                request.initials,
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.citizenName, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  request.documentType,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      request.submittedDate,
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  context.push('/official/pending');
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Review',
                        style: AppTextStyles.buttonSmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentDashboard() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _incidents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final incident = _incidents[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: incident.priorityColor.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: incident.priorityColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: incident.priorityColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: incident.priorityColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${incident.priority} Priority',
                                style: AppTextStyles.small.copyWith(
                                  color: incident.priorityColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.secondarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.more_vert_rounded,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      incident.title,
                      style: AppTextStyles.bodySemiBold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            incident.location,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          incident.date,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: AppColors.divider,
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('View Incident Details'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: incident.priorityColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: incident.priorityColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View Details',
                              style: AppTextStyles.buttonSmall.copyWith(
                                color: incident.priorityColor,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: incident.priorityColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard {
  final String label;
  final String count;
  final Color backgroundColor;
  final Color textColor;

  const _StatCard(this.label, this.count, this.backgroundColor, this.textColor);
}

class _PendingRequest {
  final String citizenName;
  final String documentType;
  final String submittedDate;
  final String initials;

  const _PendingRequest({
    required this.citizenName,
    required this.documentType,
    required this.submittedDate,
    required this.initials,
  });
}

class _Incident {
  final String title;
  final String location;
  final String date;
  final String priority;
  final Color priorityColor;

  const _Incident({
    required this.title,
    required this.location,
    required this.date,
    required this.priority,
    required this.priorityColor,
  });
}
