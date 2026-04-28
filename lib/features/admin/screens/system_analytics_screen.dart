import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SystemAnalyticsScreen extends StatelessWidget {
  const SystemAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('system_stats')
            .doc('global')
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? const <String, dynamic>{};
          final updatedAt = data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : null;

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
                      'Spark-Safe Metrics',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      updatedAt == null
                          ? 'No aggregate document found at system_stats/global yet.'
                          : 'Last updated ${DateFormat.yMMMd().add_jm().format(updatedAt)}',
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
                    label: 'Citizens',
                    value: _intText(data['totalCitizens']),
                    icon: Icons.people_outline,
                    color: AppColors.brandGreen,
                  ),
                  _MetricCard(
                    label: 'GN Officers',
                    value: _intText(data['totalGnOfficers']),
                    icon: Icons.badge_outlined,
                    color: AppColors.statusReview,
                  ),
                  _MetricCard(
                    label: 'Committee',
                    value: _intText(data['totalCommitteeMembers']),
                    icon: Icons.groups_outlined,
                    color: AppColors.info,
                  ),
                  _MetricCard(
                    label: 'Pending Requests',
                    value: _intText(data['pendingRequests']),
                    icon: Icons.pending_actions_outlined,
                    color: AppColors.statusPending,
                  ),
                  _MetricCard(
                    label: 'Open Incidents',
                    value: _intText(data['openIncidents']),
                    icon: Icons.warning_amber_outlined,
                    color: AppColors.error,
                  ),
                  _MetricCard(
                    label: 'Pending Posts',
                    value: _intText(data['pendingCommunityPosts']),
                    icon: Icons.forum_outlined,
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Analytics are read from one aggregate document to avoid collection scans on the Firebase Spark Plan. Update system_stats/global during admin/GN write flows or from Firebase console during testing.',
                style: AppTextStyles.caption,
              ),
            ],
          );
        },
      ),
    );
  }

  static String _intText(dynamic value) {
    if (value is int) return '$value';
    if (value is num) return value.toInt().toString();
    return '0';
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
