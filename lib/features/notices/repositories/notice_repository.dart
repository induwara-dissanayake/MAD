import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/notice_model.dart';

final noticeRepositoryProvider = Provider<NoticeRepository>((ref) {
  return NoticeRepository(FirebaseFirestore.instance);
});

final noticesProvider = StreamProvider<List<NoticeModel>>((ref) {
  return ref.watch(noticeRepositoryProvider).getNotices();
});

class NoticeRepository {
  final FirebaseFirestore _firestore;

  NoticeRepository(this._firestore);

  Stream<List<NoticeModel>> getNotices() {
    return _firestore
        .collection('notices')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NoticeModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}
