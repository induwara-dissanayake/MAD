import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/request_model.dart';
import '../../../core/models/dashboard_metrics.dart';

final officialRepositoryProvider = Provider<OfficialRepository>((ref) {
  return OfficialRepository(FirebaseFirestore.instance);
});

final dashboardMetricsProvider = StreamProvider<DashboardMetrics>((ref) {
  return ref.watch(officialRepositoryProvider).getDashboardMetrics();
});

class OfficialRepository {
  final FirebaseFirestore _firestore;
  static const int pageSize = 10;

  OfficialRepository(this._firestore);

  /// Get non-approved requests ordered by latest submission first.
  /// Filtering by status is done in code to avoid Firestore composite index issues.
  Stream<List<RequestModel>> getPendingRequests() {
    return _firestore
        .collection('requests')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => RequestModel.fromMap(doc.data(), doc.id))
          .where((request) => request.status != 'Approved')
          .toList();

      return requests;
    });
  }

  /// Get a single request by ID for review
  Stream<RequestModel?> getRequestById(String id) {
    return _firestore.collection('requests').doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return RequestModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Approve a request with remarks
  Future<void> approveRequest({
    required String requestId,
    required String approvedBy,
    required String remarks,
  }) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': 'Approved',
      'processedAt': FieldValue.serverTimestamp(),
      'processedBy': approvedBy,
      'remarks': remarks,
    });
  }

  /// Reject a request with reason
  Future<void> rejectRequest({
    required String requestId,
    required String rejectionReason,
  }) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': 'Rejected',
      'rejectionReason': rejectionReason,
      'processedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Request more information from citizen
  Future<void> requestMoreInfo({
    required String requestId,
    required String infoNeeded,
  }) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': 'More Info Required',
      'infoRequestDetails': {'details': infoNeeded},
      'processedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get dashboard metrics (pending, approved this month, rejected this month)
  /// Avoids composite queries by filtering dates in code
  Stream<DashboardMetrics> getDashboardMetrics() {
    return _firestore
        .collection('requests')
        .snapshots()
        .asyncMap((snapshot) async {
      // Get current month start
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      int totalPending = 0;
      int approvedThisMonth = 0;
      int rejectedThisMonth = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'];
        final processedAt = data['processedAt'];

        if (status == 'Pending') {
          totalPending++;
        } else if (status == 'Approved') {
          if (processedAt != null) {
            final date = processedAt.toDate();
            if (date.isAfter(monthStart)) {
              approvedThisMonth++;
            }
          }
        } else if (status == 'Rejected') {
          if (processedAt != null) {
            final date = processedAt.toDate();
            if (date.isAfter(monthStart)) {
              rejectedThisMonth++;
            }
          }
        }
      }

      return DashboardMetrics(
        totalPending: totalPending,
        approvedThisMonth: approvedThisMonth,
        rejectedThisMonth: rejectedThisMonth,
        lastUpdated: DateTime.now(),
      );
    });
  }

  /// Get last document reference for pagination
  Future<DocumentSnapshot?> getLastDocumentSnapshot(
    List<RequestModel> currentDocuments,
  ) async {
    if (currentDocuments.isEmpty) return null;

    final lastId = currentDocuments.last.id;
    return _firestore.collection('requests').doc(lastId).get();
  }
}
