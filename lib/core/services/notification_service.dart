import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(FirebaseFirestore.instance);
});

class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService(this._firestore);

  /// Send a notification to a user by creating a doc in the notifications collection
  Future<void> sendNotification({
    required String userId,
    required String type, // 'approval', 'rejection', 'info_request'
    required String title,
    required String message,
    String? requestId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'requestId': requestId,
      'isRead': false,
      'createdAt': Timestamp.now(),
    });
  }

  /// Retrieve all notifications for a user as a stream for real-time updates
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs.map((doc) {
            return NotificationModel.fromMap(doc.data(), doc.id);
          }).toList();
          return notifications;
        });
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }
}
