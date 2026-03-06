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

final requestDetailProvider = StreamProvider.family<RequestModel?, String>((ref, id) {
  return ref.watch(documentRepositoryProvider).getRequest(id);
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
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RequestModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Stream<RequestModel?> getRequest(String id) {
    return _firestore.collection('requests').doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return RequestModel.fromMap(doc.data()!, doc.id);
    });
  }
}
