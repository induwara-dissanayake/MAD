import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/incident_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../repositories/incident_repository.dart';

class IncidentDashboardScreen extends ConsumerStatefulWidget {
  const IncidentDashboardScreen({super.key});

  @override
  ConsumerState<IncidentDashboardScreen> createState() =>
      _IncidentDashboardScreenState();
}

class _IncidentDashboardScreenState
    extends ConsumerState<IncidentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<String> _tabs = ['All', 'Critical', 'In Progress', 'Resolved'];

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

  List<IncidentModel> _filteredIncidents(
    List<IncidentModel> incidents,
    int tab,
  ) {
    switch (tab) {
      case 1:
        return incidents.where((i) => i.priority == 'Critical').toList();
      case 2:
        return incidents.where((i) => i.status == 'In Progress').toList();
      case 3:
        return incidents.where((i) => i.status == 'Resolved').toList();
      default:
        return incidents;
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
      case 'Fire':
        return Icons.local_fire_department_rounded;
      case 'Flood':
        return Icons.water_rounded;
      case 'Medical':
        return Icons.medical_services_rounded;
      case 'Crime':
        return Icons.gavel_rounded;
      case 'Accident':
        return Icons.car_crash_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(incidentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/official/dashboard');
            }
          },
        ),
        title: const Text('Incident Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          onTap: (_) => setState(() {}),
        ),
      ),
      body: incidentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed to load incidents: $error')),
        data: (incidents) {
          return TabBarView(
            controller: _tabController,
            children: List.generate(_tabs.length, (tabIndex) {
              final items = _filteredIncidents(incidents, tabIndex);
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 64,
                        color: AppColors.success.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No incidents found',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _buildIncidentCard(items[index]),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildIncidentCard(IncidentModel incident) {
    final priorityColor = _priorityColor(incident.priority);
    return GestureDetector(
      onTap: () => _showIncidentDetail(incident),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.6)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
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
                            child: Icon(
                              _typeIcon(incident.type),
                              color: priorityColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${incident.type} alert',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  incident.location,
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
                          _badge(incident.priority, priorityColor),
                          const SizedBox(width: 8),
                          _badge(
                            incident.status,
                            _statusColor(incident.status),
                          ),
                          const Spacer(),
                          Text(
                            _timeAgo(incident.createdAt),
                            style: AppTextStyles.small.copyWith(fontSize: 11),
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
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.small.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Resolved':
        return AppColors.success;
      case 'In Progress':
        return AppColors.warning;
      case 'Acknowledged':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showIncidentDetail(IncidentModel incident) {
    String selectedStatus = incident.status;
    final notesController = TextEditingController(text: incident.responseNotes);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.76,
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
                      Text('${incident.type} alert', style: AppTextStyles.h2),
                      const SizedBox(height: 8),
                      Text('Ref: ${incident.id}', style: AppTextStyles.small),
                      const SizedBox(height: 20),
                      _detailRow(
                        Icons.location_on_rounded,
                        'Location',
                        incident.location,
                      ),
                      _detailRow(
                        Icons.person_rounded,
                        'Reporter',
                        '${incident.reporterName} (${incident.reporterNic})',
                      ),
                      _detailRow(
                        Icons.access_time_rounded,
                        'Reported',
                        _timeAgo(incident.createdAt),
                      ),
                      const SizedBox(height: 16),
                      Text('Description', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      Text(incident.description, style: AppTextStyles.body),
                      const SizedBox(height: 24),
                      Text('Status', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        items: const [
                          DropdownMenuItem(
                            value: 'Acknowledged',
                            child: Text('Acknowledged'),
                          ),
                          DropdownMenuItem(
                            value: 'In Progress',
                            child: Text('In Progress'),
                          ),
                          DropdownMenuItem(
                            value: 'Resolved',
                            child: Text('Resolved'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => selectedStatus = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Response notes',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid == null) return;
                            await ref
                                .read(incidentRepositoryProvider)
                                .updateStatus(
                                  incidentId: incident.id,
                                  status: selectedStatus,
                                  responderUid: uid,
                                  notes: notesController.text.trim(),
                                );
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Update Incident'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(notesController.dispose);
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
