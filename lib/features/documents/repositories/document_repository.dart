import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/request_model.dart';
import '../../../../core/services/auth_service.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(FirebaseFirestore.instance);
});

final userRequestsProvider = StreamProvider<List<RequestModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(documentRepositoryProvider).getUserRequests(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});

final requestDetailProvider = StreamProvider.family<RequestModel?, String>((
  ref,
  id,
) {
  return ref.watch(documentRepositoryProvider).getRequest(id);
});

final pendingRequestsProvider =
    StreamProvider.family<List<RequestModel>, String?>((ref, division) {
  return ref.watch(documentRepositoryProvider).getPendingRequests(division);
});

class DocumentRepository {
  final FirebaseFirestore _firestore;

  DocumentRepository(this._firestore);

  Future<void> createRequest(RequestModel request) async {
    await _firestore.collection('requests').add(request.toMap());
  }

  Stream<List<RequestModel>> getUserRequests(String userId) {
    return _firestore
        .collection('requests')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs.map((doc) {
            return RequestModel.fromMap(doc.data(), doc.id);
          }).toList();

          requests.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return requests;
        });
  }

  Stream<RequestModel?> getRequest(String id) {
    return _firestore.collection('requests').doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return RequestModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Get pending requests for GN Officer
  /// Fetches all requests and filters by status in memory for flexibility
  Stream<List<RequestModel>> getPendingRequests(String? division) {
    print('🔍 getPendingRequests() called');

    return _firestore
        .collection('requests')
        .snapshots()
        .map((snapshot) {
          print('📦 Total requests in collection: ${snapshot.docs.length}');

          final requests = <RequestModel>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final status = data['status'] as String?;
            print('   • Doc: ${doc.id}');
            print('     Status: "$status" (type: ${status.runtimeType})');
            print('     Name: ${data['fullName']}');

            // Match both "Pending" and "pending"
            if (status?.toLowerCase() == 'pending') {
              requests.add(RequestModel.fromMap(data, doc.id));
              print('     ✅ ADDED (status matches)');
            } else {
              print('     ❌ SKIPPED (status: $status)');
            }
          }

          print('📋 Total pending requests: ${requests.length}');
          requests.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return requests;
        });
  }

  /// Get request by ID for review
  Stream<RequestModel?> getRequestById(String id) {
    return _firestore.collection('requests').doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return RequestModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Approve a request and update status
  Future<void> approveRequest({
    required String requestId,
    required String approvedBy,
    String? remarks,
  }) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': 'approved',
      'processedAt': FieldValue.serverTimestamp(),
      'processedBy': approvedBy,
      'remarks': remarks,
    });
  }

  /// Reject a request and update status with reason
  Future<void> rejectRequest({
    required String requestId,
    required String rejectionReason,
  }) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': 'rejected',
      'rejectionReason': rejectionReason,
      'processedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Request more information for a request
  Future<void> requestMoreInfo({
    required String requestId,
    required String infoNeeded,
  }) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': 'info_requested',
      'infoRequestDetails': {'details': infoNeeded},
      'processedAt': FieldValue.serverTimestamp(),
    });
  }
}
