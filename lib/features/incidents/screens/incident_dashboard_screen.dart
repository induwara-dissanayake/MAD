import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class IncidentDashboardScreen extends StatefulWidget {
  const IncidentDashboardScreen({super.key});

  @override
  State<IncidentDashboardScreen> createState() =>
      _IncidentDashboardScreenState();
}

class _IncidentDashboardScreenState extends State<IncidentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<String> _tabs = ['All', 'Critical', 'In Progress', 'Resolved'];

  final List<_Incident> _incidents = [
    _Incident(
      id: 'INC-001',
      title: 'Road Damage on Kandy Road',
      type: 'Infrastructure',
      location: 'Kandy Rd, Near Temple',
      reporter: 'Kasun Perera',
      time: '15 min ago',
      priority: 'Critical',
      status: 'Open',
      description: 'Large pothole causing danger to traffic and pedestrians.',
    ),
    _Incident(
      id: 'INC-002',
      title: 'Fallen Tree Blocking Path',
      type: 'Environment',
      location: 'Village Rd, Sector 3',
      reporter: 'Nimal Silva',
      time: '1 hr ago',
      priority: 'High',
      status: 'In Progress',
      description: 'Tree fell due to storm blocking pedestrian walkway.',
    ),
    _Incident(
      id: 'INC-003',
      title: 'Water Supply Disruption',
      type: 'Utilities',
      location: 'Main Water Line',
      reporter: 'Sunil Fernando',
      time: '3 hrs ago',
      priority: 'High',
      status: 'In Progress',
      description: 'No water supply to households in the eastern sector.',
    ),
    _Incident(
      id: 'INC-004',
      title: 'Stray Dog Problem',
      type: 'Animal Control',
      location: 'Market Area',
      reporter: 'Amaya Dias',
      time: '5 hrs ago',
      priority: 'Medium',
      status: 'Open',
      description: 'Pack of stray dogs near market causing safety concerns.',
    ),
    _Incident(
      id: 'INC-005',
      title: 'Garbage Accumulation',
      type: 'Sanitation',
      location: 'Community Park',
      reporter: 'Ranjith Kumara',
      time: '1 day ago',
      priority: 'Low',
      status: 'Resolved',
      description: 'Garbage not collected for a week near community park.',
    ),
    _Incident(
      id: 'INC-006',
      title: 'Streetlight Not Working',
      type: 'Infrastructure',
      location: 'Temple Rd, Pole #12',
      reporter: 'Lahiru Mendis',
      time: '2 days ago',
      priority: 'Low',
      status: 'Resolved',
      description: 'Streetlight has been off for 3 nights.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_Incident> _filteredIncidents(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return _incidents.where((i) => i.priority == 'Critical').toList();
      case 2:
        return _incidents.where((i) => i.status == 'In Progress').toList();
      case 3:
        return _incidents.where((i) => i.status == 'Resolved').toList();
      default:
        return _incidents;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return AppColors.error;
      case 'High':
        return const Color(0xFFF57C00);
      case 'Medium':
        return AppColors.warning;
      case 'Low':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Infrastructure':
        return Icons.construction_rounded;
      case 'Environment':
        return Icons.park_rounded;
      case 'Utilities':
        return Icons.water_drop_rounded;
      case 'Animal Control':
        return Icons.pets_rounded;
      case 'Sanitation':
        return Icons.delete_rounded;
      default:
        return Icons.report_rounded;
    }
  }

  void _showIncidentDetail(_Incident incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.65,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _priorityColor(incident.priority)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            incident.priority.toUpperCase(),
                            style: AppTextStyles.small.copyWith(
                              color: _priorityColor(incident.priority),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: incident.status == 'Resolved'
                                ? AppColors.successLight
                                : AppColors.warningLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            incident.status,
                            style: AppTextStyles.small.copyWith(
                              color: incident.status == 'Resolved'
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(incident.id,
                            style: AppTextStyles.small
                                .copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(incident.title, style: AppTextStyles.h2),
                    const SizedBox(height: 20),
                    _detailRow(
                        Icons.category_rounded, 'Type', incident.type),
                    _detailRow(Icons.location_on_rounded, 'Location',
                        incident.location),
                    _detailRow(Icons.person_rounded, 'Reporter',
                        incident.reporter),
                    _detailRow(
                        Icons.access_time_rounded, 'Reported', incident.time),
                    const SizedBox(height: 16),
                    Text('Description', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        incident.description,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (incident.status != 'Resolved')
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.assignment_ind_rounded,
                                  size: 20),
                              label: const Text('Assign'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                    color: AppColors.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.check_circle_rounded,
                                  size: 20),
                              label: const Text('Resolve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Incident Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          onTap: (_) => setState(() {}),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create incident form coming soon')),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Report'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabs.length, (tabIndex) {
          final items = _filteredIncidents(tabIndex);
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 64, color: AppColors.success.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text('No incidents found',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
            );
          }
          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final incident = items[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 40,
                    child: FadeInAnimation(
                      child: _buildIncidentCard(incident),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildIncidentCard(_Incident incident) {
    final priorityColor = _priorityColor(incident.priority);
    return GestureDetector(
      onTap: () => _showIncidentDetail(incident),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Priority stripe
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_typeIcon(incident.type),
                                color: priorityColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  incident.title,
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${incident.type} • ${incident.location}',
                                  style: AppTextStyles.small,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              incident.priority,
                              style: AppTextStyles.small.copyWith(
                                color: priorityColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: incident.status == 'Resolved'
                                  ? AppColors.successLight
                                  : incident.status == 'In Progress'
                                      ? AppColors.warningLight
                                      : AppColors.surfaceGrey,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              incident.status,
                              style: AppTextStyles.small.copyWith(
                                color: incident.status == 'Resolved'
                                    ? AppColors.success
                                    : incident.status == 'In Progress'
                                        ? AppColors.warning
                                        : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.person_outline_rounded,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(incident.reporter,
                              style: AppTextStyles.small
                                  .copyWith(fontSize: 11)),
                          const SizedBox(width: 8),
                          Text(incident.time,
                              style: AppTextStyles.small
                                  .copyWith(fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Incident {
  final String id;
  final String title;
  final String type;
  final String location;
  final String reporter;
  final String time;
  final String priority;
  final String status;
  final String description;
  const _Incident({
    required this.id,
    required this.title,
    required this.type,
    required this.location,
    required this.reporter,
    required this.time,
    required this.priority,
    required this.status,
    required this.description,
  });
}
