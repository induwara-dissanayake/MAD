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
  final service = ref.read(requestApprovalServiceProvider);
  await service.approveRequest(
    requestId: params.requestId,
    approverUid: params.approvedBy,
    remarks: params.remarks,
  );

  ref.invalidate(dashboardMetricsProvider);
});

final rejectRequestProvider =
    FutureProvider.family<void, ({String requestId, String rejectionReason, String approverUid})>(
        (ref, params) async {
  final service = ref.read(requestApprovalServiceProvider);
  await service.rejectRequest(
    requestId: params.requestId,
    rejectionReason: params.rejectionReason,
    approverUid: params.approverUid,
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
