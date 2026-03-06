import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/request_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../repositories/document_repository.dart';

class RequestDetailScreen extends ConsumerWidget {
  final String trackingId;
  final String documentType;
  final String status;

  const RequestDetailScreen({
    super.key,
    required this.trackingId,
    required this.documentType,
    required this.status,
  });

  Map<String, String> _getApplicationDetails(RequestModel request) => {
        'Document Type': request.documentType,
        'Full Name': request.fullName,
        'NIC Number': request.nic,
        'Address': request.address,
        'Reason': request.reason,
        'Submitted Date': DateFormat.yMMMd().format(request.submittedAt),
      };

  String _getGnRemarks(RequestModel request) {
    if (request.status == 'Approved') {
      return 'All documents verified. The applicant has been residing in this area for over 15 years. Character is satisfactory.';
    }
    if (request.status == 'Rejected') {
      return request.rejectionReason ??
          'The NIC copy provided is not legible. Please resubmit with a clear copy of the NIC (front and back).';
    }
    return '';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppColors.success;
      case 'Rejected':
        return AppColors.error;
      case 'In Review':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Approved':
        return Icons.check_circle_rounded;
      case 'Rejected':
        return Icons.cancel_rounded;
      case 'In Review':
        return Icons.rate_review_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(requestDetailProvider(trackingId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text('Request Details', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: requestAsync.when(
        data: (request) {
          if (request == null) {
            return const Center(child: Text('Request not found'));
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                const Divider(height: 1, color: AppColors.divider),
                _buildStatusHeader(request),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimeline(request),
                      const SizedBox(height: 24),
                      _buildDetailsCard(request),
                      if (_getGnRemarks(request).isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildRemarksCard(request),
                      ],
                      const SizedBox(height: 24),
                      _buildActionButtons(context, request),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  // ── Status Header ─────────────────────────────────────────────────────
  Widget _buildStatusHeader(RequestModel request) {
    final color = _getStatusColor(request.status);
    final icon = _getStatusIcon(request.status);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.status,
                  style: AppTextStyles.h3.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  request.id.isNotEmpty ? request.id.substring(0, 8) : '...',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Timeline ──────────────────────────────────────────────────────────
  Widget _buildTimeline(RequestModel request) {
    final steps = [
      _TimelineStep(
        'Application Submitted',
        DateFormat.yMMMd().add_jm().format(request.submittedAt),
        true,
      ),
      _TimelineStep(
        'Under Review',
        request.status != 'Pending' ? 'In Progress' : 'Pending',
        request.status != 'Pending',
      ),
      _TimelineStep(
        'GN Verification',
        request.status == 'Approved' || request.status == 'Rejected'
            ? 'Completed'
            : 'Pending',
        request.status == 'Approved' || request.status == 'Rejected',
      ),
      _TimelineStep(
        request.status == 'Rejected'
            ? 'Application Rejected'
            : 'Ready for Collection',
        request.status == 'Approved' || request.status == 'Rejected'
            ? 'Completed'
            : 'Pending',
        request.status == 'Approved' || request.status == 'Rejected',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progress', style: AppTextStyles.bodySemiBold),
        const SizedBox(height: 14),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isLast = index == steps.length - 1;
          final color = _getStatusColor(request.status);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: step.isCompleted
                          ? color
                          : AppColors.disabledBackground,
                      shape: BoxShape.circle,
                    ),
                    child: step.isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          )
                        : Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.disabled,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: step.isCompleted
                          ? color.withOpacity(0.3)
                          : AppColors.disabledBackground,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: step.isCompleted
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.subtitle,
                        style: AppTextStyles.small.copyWith(
                          color: step.isCompleted
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  // ── Details card ──────────────────────────────────────────────────────
  Widget _buildDetailsCard(RequestModel request) {
    final details = _getApplicationDetails(request);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Application Details', style: AppTextStyles.bodySemiBold),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card,
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
            children: details.entries.map((entry) {
              final isLast = entry.key == details.keys.last;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(entry.key, style: AppTextStyles.caption),
                        ),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 1, color: AppColors.divider),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Remarks card ──────────────────────────────────────────────────────
  Widget _buildRemarksCard(RequestModel request) {
    final isRejected = request.status == 'Rejected';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GN Remarks', style: AppTextStyles.bodySemiBold),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isRejected ? AppColors.errorLight : AppColors.successLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (isRejected ? AppColors.error : AppColors.success)
                  .withOpacity(0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isRejected
                    ? Icons.info_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: isRejected ? AppColors.error : AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getGnRemarks(request),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────
  Widget _buildActionButtons(BuildContext context, RequestModel request) {
    if (request.status == 'Rejected') {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.refresh_rounded, size: 20),
          label: const Text('Resubmit Application'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _TimelineStep {
  final String title;
  final String subtitle;
  final bool isCompleted;

  const _TimelineStep(this.title, this.subtitle, this.isCompleted);
}
