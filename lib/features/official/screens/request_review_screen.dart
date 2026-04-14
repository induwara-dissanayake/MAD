import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/vc_card.dart';
import '../../../shared/widgets/vc_status_badge.dart';
import '../controllers/official_controller.dart';

class RequestReviewScreen extends ConsumerStatefulWidget {
  final String requestId;

  const RequestReviewScreen({
    super.key,
    required this.requestId,
  });

  @override
  ConsumerState<RequestReviewScreen> createState() =>
      _RequestReviewScreenState();
}

class _RequestReviewScreenState extends ConsumerState<RequestReviewScreen> {
  final _remarksController = TextEditingController();
  bool _isApproving = false;
  bool _isRejecting = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(requestDetailProvider(widget.requestId));
    final authService = ref.watch(authServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceGrey.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          'Review Request',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: requestAsync.when(
        data: (request) {
          if (request == null) {
            return Center(
              child: Text(
                'Request not found',
                style: AppTextStyles.body,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Citizen Info Card
                _buildCitizenCard(request),
                const SizedBox(height: 24),

                // Request Details Card
                _buildRequestDetailsCard(request),
                const SizedBox(height: 24),

                // Form Data Section
                if (request.formData != null &&
                    request.formData!.isNotEmpty) ...[
                  Text(
                    'Application Information',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFormDataSection(request.formData!),
                  const SizedBox(height: 24),
                ],

                // Remarks Field
                Text(
                  'GN Officer Remarks',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _remarksController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add remarks for this request (required for rejection)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceGrey.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isApproving || _isRejecting
                            ? null
                            : () => _showRejectDialog(
                                  context,
                                  authService.currentUser?.uid,
                                ),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isApproving || _isRejecting
                            ? null
                            : () => _approveRequest(authService.currentUser?.uid),
                        icon: _isApproving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.check_circle_rounded),
                        label: Text(
                          _isApproving ? 'Approving...' : 'Approve',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading request: $error',
                style: AppTextStyles.body.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCitizenCard(dynamic request) {
    return VcCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Applicant',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      request.fullName,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow('NIC Number', request.nic),
          const SizedBox(height: 12),
          _buildDetailRow('Address', request.address),
        ],
      ),
    );
  }

  Widget _buildRequestDetailsCard(dynamic request) {
    return VcCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Status',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  VcStatusBadge(
                    label: request.status,
                    type: statusTypeFromString(request.status),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Submitted',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(request.submittedAt),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildDetailRow('Document Type', request.documentType),
          const SizedBox(height: 12),
          _buildDetailRow('Reason', request.reason),
        ],
      ),
    );
  }

  Widget _buildFormDataSection(Map<String, String> formData) {
    return VcCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...formData.entries.map((entry) {
            if (entry.key != 'Full Name' &&
                entry.key != 'NIC Number' &&
                entry.key != 'Address') {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(entry.key, entry.value),
                  const SizedBox(height: 12),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _approveRequest(String? userId) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    setState(() => _isApproving = true);

    try {
      await ref.read(approveRequestProvider(
        (
          requestId: widget.requestId,
          approvedBy: userId,
          remarks: _remarksController.text.trim(),
        ),
      ).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request approved')),
        );
        context.go('/official/requests/pending');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving request: $e')),
        );
        setState(() => _isApproving = false);
      }
    }
  }

  Future<void> _rejectRequest(String reason, String? approverUid) async {
    if (approverUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    setState(() => _isRejecting = true);

    try {
      await ref.read(rejectRequestProvider(
        (
          requestId: widget.requestId,
          rejectionReason: reason,
          approverUid: approverUid,
        ),
      ).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request rejected')),
        );
        context.go('/official/requests/pending');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting request: $e')),
        );
        setState(() => _isRejecting = false);
      }
    }
  }

  void _showRejectDialog(BuildContext context, String? approverUid) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            'Reject Request',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please provide a rejection reason:',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(
                  hintText: 'Reason for rejection',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: reasonController.text.trim().isEmpty
                  ? null
                  : () {
                      context.pop();
                      _rejectRequest(reasonController.text.trim(), approverUid);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );
  }

}
