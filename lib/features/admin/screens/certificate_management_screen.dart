import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/request_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/vc_status_badge.dart';
import '../controllers/admin_controller.dart';

class CertificateManagementScreen extends ConsumerStatefulWidget {
  const CertificateManagementScreen({super.key});

  @override
  ConsumerState<CertificateManagementScreen> createState() =>
      _CertificateManagementScreenState();
}

class _CertificateManagementScreenState
    extends ConsumerState<CertificateManagementScreen> {
  final _searchController = TextEditingController();
  String _selectedScope = 'All';
  String _selectedStatus = 'All';

  final List<String> _scopeOptions = const ['All', 'Pending', 'Reviewed'];
  final List<String> _statusOptions = const [
    'All',
    'Pending',
    'Approved',
    'Rejected',
    'More Info Required',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(allRequestsProvider);
    final reviewedAsync = ref.watch(allCertificateRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go('/admin/dashboard');
          },
        ),
        title: Text(
          'Certificate Management',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(allRequestsProvider);
              ref.invalidate(allCertificateRequestsProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by name, NIC, or document type',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.4),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _scopeOptions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final option = _scopeOptions[index];
                      final isSelected = option == _selectedScope;
                      return ChoiceChip(
                        label: Text(option),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedScope = option),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border.withValues(alpha: 0.4),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusOptions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final option = _statusOptions[index];
                      final isSelected = option == _selectedStatus;
                      return ChoiceChip(
                        label: Text(option),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedStatus = option),
                        selectedColor: AppColors.info,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.info
                                : AppColors.border.withValues(alpha: 0.4),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: pendingAsync.when(
              data: (pendingRequests) {
                return reviewedAsync.when(
                  data: (reviewedRequests) {
                    final records = _combinedRecords(
                      pendingRequests,
                      reviewedRequests,
                    );
                    final filtered = _filterRecords(records);

                    if (filtered.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildRecordCard(filtered[index]);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Failed to load reviewed certificates: $error'),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Failed to load requests: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_CertificateRecord> _combinedRecords(
    List<RequestModel> pendingRequests,
    List<RequestModel> reviewedRequests,
  ) {
    final records = <_CertificateRecord>[
      ...pendingRequests.map(
        (request) => _CertificateRecord(
          request: request,
          source: 'pending',
        ),
      ),
      ...reviewedRequests.map(
        (request) => _CertificateRecord(
          request: request,
          source: 'reviewed',
        ),
      ),
    ];

    records.sort((a, b) => b.request.submittedAt.compareTo(a.request.submittedAt));
    return records;
  }

  List<_CertificateRecord> _filterRecords(List<_CertificateRecord> records) {
    final query = _searchController.text.trim().toLowerCase();

    return records.where((record) {
      final request = record.request;
      final scopeMatch = _selectedScope == 'All' ||
          (_selectedScope == 'Pending' && record.source == 'pending') ||
          (_selectedScope == 'Reviewed' && record.source == 'reviewed');
      final statusMatch = _selectedStatus == 'All' ||
          request.status.toLowerCase() == _selectedStatus.toLowerCase();
      final searchMatch = query.isEmpty ||
          request.fullName.toLowerCase().contains(query) ||
          request.nic.toLowerCase().contains(query) ||
          request.documentType.toLowerCase().contains(query);

      return scopeMatch && statusMatch && searchMatch;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.surfaceGrey,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              color: AppColors.textMuted,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No certificate records found',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your filters or search query.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(_CertificateRecord record) {
    final request = record.request;
    final statusColor = _statusColor(request.status);
    final isPending = record.source == 'pending' && request.status == 'Pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_statusIcon(request.status), color: statusColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.fullName.isEmpty ? 'Unknown Applicant' : request.fullName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${request.documentType} • ${request.nic}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              VcStatusBadge(
                label: request.status,
                type: statusTypeFromString(request.status),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetaItem(
                  'Submitted',
                  DateFormat.yMMMd().add_jm().format(request.submittedAt),
                ),
              ),
              Expanded(
                child: _buildMetaItem(
                  'Source',
                  record.source == 'pending' ? 'Requests' : 'certificaterq',
                ),
              ),
            ],
          ),
          if (request.remarks != null && request.remarks!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Remarks',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              request.remarks!,
              style: AppTextStyles.body.copyWith(height: 1.4),
            ),
          ],
          if (record.source == 'reviewed' && request.processedBy != null) ...[
            const SizedBox(height: 12),
            Text(
              'Reviewed by: ${request.processedBy}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    context.push('/official/requests/${request.id}/review'),
                icon: const Icon(Icons.rate_review_rounded),
                label: const Text('Open Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppColors.success;
      case 'Rejected':
        return AppColors.error;
      case 'More Info Required':
        return AppColors.warning;
      case 'Pending':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Approved':
        return Icons.check_circle_rounded;
      case 'Rejected':
        return Icons.cancel_rounded;
      case 'More Info Required':
        return Icons.info_rounded;
      case 'Pending':
        return Icons.hourglass_bottom_rounded;
      default:
        return Icons.description_rounded;
    }
  }
}

class _CertificateRecord {
  final RequestModel request;
  final String source;

  const _CertificateRecord({
    required this.request,
    required this.source,
  });
}
