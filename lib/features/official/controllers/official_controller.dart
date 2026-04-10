import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/request_model.dart';
import '../../../core/services/request_approval_service.dart';
import '../repositories/official_repository.dart';

final requestDetailProvider =
    StreamProvider.family<RequestModel?, String>((ref, requestId) {
  final repository = ref.watch(officialRepositoryProvider);
  return repository.getRequestById(requestId);
});

final approveRequestProvider =
    FutureProvider.family<void, ({String requestId, String approvedBy, String remarks})>(
        (ref, params) async {
  final repository = ref.watch(officialRepositoryProvider);
  await repository.approveRequest(
    requestId: params.requestId,
    approvedBy: params.approvedBy,
    remarks: params.remarks,
  );

  // Optional: Trigger notification through RequestApprovalService
  ref.invalidate(dashboardMetricsProvider);
});

final rejectRequestProvider =
    FutureProvider.family<void, ({String requestId, String rejectionReason})>(
        (ref, params) async {
  final repository = ref.watch(officialRepositoryProvider);
  await repository.rejectRequest(
    requestId: params.requestId,
    rejectionReason: params.rejectionReason,
  );

  ref.invalidate(dashboardMetricsProvider);
});

final requestMoreInfoProvider = FutureProvider.family<void,
    ({String requestId, String infoNeeded})>((ref, params) async {
  final repository = ref.watch(officialRepositoryProvider);
  await repository.requestMoreInfo(
    requestId: params.requestId,
    infoNeeded: params.infoNeeded,
  );

  ref.invalidate(dashboardMetricsProvider);
});
