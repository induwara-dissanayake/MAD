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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
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
                      'Welcome, Officer',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textOnPrimary.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nimal Fernando',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.textOnPrimary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'NF',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.textOnPrimary,
            indicatorWeight: 3,
            labelColor: AppColors.textOnPrimary,
            unselectedLabelColor: AppColors.textOnPrimary.withOpacity(0.6),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Incidents'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _stats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final stat = _stats[index];
          return Container(
            width: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: stat.backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  stat.count,
                  style: AppTextStyles.h1.copyWith(
                    color: stat.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                  ),
                ),
                Text(
                  stat.label,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: stat.textColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.h3),
        const SizedBox(height: 14),
        _buildActionCard(
          title: 'Review Requests',
          icon: Icons.rate_review_outlined,
          backgroundColor: AppColors.accentBlue,
          onTap: () {
            context.push('/official/pending');
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          title: 'Post Notice',
          icon: Icons.campaign_outlined,
          backgroundColor: AppColors.accentYellow,
          onTap: () {
            context.push('/official/post-notice');
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          title: 'Broadcast Message',
          icon: Icons.cell_tower_rounded,
          backgroundColor: AppColors.accentPurple,
          onTap: () {
            context.push('/official/broadcast');
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          title: 'Incident Dashboard',
          icon: Icons.report_rounded,
          backgroundColor: AppColors.accentRed,
          onTap: () {
            context.push('/incidents');
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          title: 'Committee Tasks',
          icon: Icons.task_alt_rounded,
          backgroundColor: AppColors.accentGreen,
          onTap: () {
            context.push('/committee/tasks');
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          title: 'Community Polls',
          icon: Icons.poll_rounded,
          backgroundColor: AppColors.accentBlue,
          onTap: () {
            context.push('/committee/polls');
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          title: 'Admin Panel',
          icon: Icons.admin_panel_settings_rounded,
          backgroundColor: const Color(0xFFF3E5F5),
          onTap: () {
            context.push('/admin/dashboard');
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          title: 'Register Citizen',
          icon: Icons.person_add_alt_1_rounded,
          backgroundColor: AppColors.accentGreen,
          onTap: () {
            context.push('/auth/create-resident');
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          title: 'Register Committee Member',
          icon: Icons.group_add_rounded,
          backgroundColor: AppColors.accentPurple,
          onTap: () {
            context.push('/auth/add-member');
          },
        ),
        const SizedBox(height: 10),
        _buildActionCard(
          title: 'Registered Users',
          icon: Icons.people_alt_rounded,
          backgroundColor: AppColors.accentBlue,
          onTap: () {
            context.push('/official/registered-users');
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(title, style: AppTextStyles.bodySemiBold)),
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

  Widget _buildRecentPendingRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Pending Requests', style: AppTextStyles.h3),
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: () {
                  context.push('/official/pending');
                },
                child: Text(
                  'View All',
                  style: AppTextStyles.captionMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                request.initials,
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
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
                const SizedBox(height: 2),
                Text(request.documentType, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  'Submitted: ${request.submittedDate}',
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                context.push('/official/pending');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                'Review',
                style: AppTextStyles.buttonSmall.copyWith(
                  color: AppColors.textOnPrimary,
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
      padding: const EdgeInsets.all(20),
      itemCount: _incidents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final incident = _incidents[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: incident.priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${incident.priority} Priority',
                      style: AppTextStyles.small.copyWith(
                        color: incident.priorityColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.textMuted,
                    size: 20,
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
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      incident.location,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    incident.date,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('View Incident Details'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('View Details', style: AppTextStyles.buttonSmall),
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
