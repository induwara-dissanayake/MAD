import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/request_model.dart';
import '../../../core/models/dashboard_metrics.dart';
import '../../../core/models/pagination_state.dart';

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

  /// Get paginated pending requests with cursor-based pagination
  /// Returns a stream of lists where each emission contains up to [pageSize] requests
  Stream<List<RequestModel>> getPendingRequests({
    DocumentSnapshot? lastDocument,
    String? filterDocumentType,
  }) {
    Query query = _firestore
        .collection('requests')
        .where('status', isEqualTo: 'Pending')
        .orderBy('submittedAt', descending: true);

    // Apply cursor-based pagination
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    // Limit results
    query = query.limit(pageSize + 1); // +1 to check if there are more

    return query.snapshots().map((snapshot) {
      final requests = snapshot.docs.map((doc) {
        return RequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

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
  Stream<DashboardMetrics> getDashboardMetrics() {
    return _firestore
        .collection('requests')
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .asyncMap((snapshot) async {
      final totalPending = snapshot.docs.length;

      // Get current month start
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      // Count approved this month
      final approvedSnapshot = await _firestore
          .collection('requests')
          .where('status', isEqualTo: 'Approved')
          .where('processedAt', isGreaterThanOrEqualTo: monthStart)
          .get();

      final approvedThisMonth = approvedSnapshot.docs.length;

      // Count rejected this month
      final rejectedSnapshot = await _firestore
          .collection('requests')
          .where('status', isEqualTo: 'Rejected')
          .where('processedAt', isGreaterThanOrEqualTo: monthStart)
          .get();

      final rejectedThisMonth = rejectedSnapshot.docs.length;

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
