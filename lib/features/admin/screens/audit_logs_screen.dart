import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final _filterController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceParchment,
      appBar: AppBar(
        title: const Text('Audit Logs'),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent Activity', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Text(
                  'Shows the latest Firestore audit records. Use the filter for action, actor, or target UID.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _filterController,
                  onChanged: (value) =>
                      setState(() => _filter = value.trim().toLowerCase()),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_outlined),
                    hintText: 'Filter recent logs',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('audit_logs')
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _MessageBox(
                  message: 'Unable to load audit logs: ${snapshot.error}',
                  isError: true,
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final logs = snapshot.data!.docs.where((doc) {
                if (_filter.isEmpty) return true;
                final data = doc.data();
                final haystack = [
                  data['action'],
                  data['actorUid'],
                  data['actorRole'],
                  data['targetUid'],
                  data['targetId'],
                  data['targetCollection'],
                ].whereType<Object>().join(' ').toLowerCase();
                return haystack.contains(_filter);
              }).toList();

              if (logs.isEmpty) {
                return const _MessageBox(
                  message: 'No audit records match the current filter.',
                );
              }

              return Column(
                children: [
                  for (final doc in logs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AuditLogTile(data: doc.data(), id: doc.id),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({required this.data, required this.id});

  final Map<String, dynamic> data;
  final String id;

  @override
  Widget build(BuildContext context) {
    final createdAt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    final action = data['action']?.toString() ?? 'unknown_action';
    final target = data['targetUid']?.toString().isNotEmpty == true
        ? data['targetUid'].toString()
        : data['targetId']?.toString() ?? '-';

    return _Panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.history_rounded, color: AppColors.brandGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.replaceAll('_', ' '), style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text('Target: $target', style: AppTextStyles.caption),
                Text(
                  'Actor: ${data['actorUid'] ?? data['createdBy'] ?? '-'}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 6),
                Text('Log ID: $id', style: AppTextStyles.monoMedium),
              ],
            ),
          ),
          if (createdAt != null)
            Text(
              DateFormat.MMMd().add_jm().format(createdAt),
              style: AppTextStyles.small,
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceIvory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceWarmSand),
        boxShadow: AppColors.shadowLow,
      ),
      child: child,
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Text(
        message,
        style: AppTextStyles.caption.copyWith(
          color: isError ? AppColors.error : AppColors.inkMid,
        ),
      ),
    );
  }
}
