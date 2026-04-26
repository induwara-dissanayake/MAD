import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import 'auth_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(FirebaseFirestore.instance);
});

final userNotificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(notificationServiceProvider).getNotifications(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(userNotificationsProvider).maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService(this._firestore);

  /// Send a notification to a user by creating a doc in the notifications collection
  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? requestId,
    String? relatedId,
    String? actionRoute,
    Map<String, dynamic>? actionExtra,
  }) async {
    final extra = actionExtra == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(actionExtra);
    await _firestore.collection('notifications').add({
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'requestId': requestId,
      'relatedId': relatedId,
      'actionRoute': actionRoute,
      'actionExtra': extra,
      'isRead': false,
      'createdAt': Timestamp.now(),
    });
  }

  /// Real-time list for this user, newest first (sorted client-side to avoid
  /// requiring a composite index before indexes are deployed).
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final all = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    final toMark = all.docs.where((d) => d.data()['isRead'] != true).toList();
    if (toMark.isEmpty) return;

    const chunk = 500;
    for (var i = 0; i < toMark.length; i += chunk) {
      final slice = toMark.sublist(
        i,
        i + chunk > toMark.length ? toMark.length : i + chunk,
      );
      final batch = _firestore.batch();
      for (final doc in slice) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }
}
