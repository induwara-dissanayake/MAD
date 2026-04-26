import 'dart:math' show min;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_service.dart';

final communityBroadcastNotificationServiceProvider =
    Provider<CommunityBroadcastNotificationService>((ref) {
  return CommunityBroadcastNotificationService(
    FirebaseFirestore.instance,
    ref.watch(userServiceProvider),
  );
});

class CommunityBroadcastNotificationService {
  CommunityBroadcastNotificationService(
    this._firestore,
    this._userService,
  );

  final FirebaseFirestore _firestore;
  final UserService _userService;

  static const int _maxBatch = 500;

  /// Notifies all users in the same [village] except [senderUserId] (batch chunking).
  Future<void> broadcastImportantMessage({
    required String village,
    required String senderUserId,
    required String roomName,
    String? messagePreview,
  }) async {
    if (village.isEmpty) return;

    final recipientIds = await _userService.getUserUidsInVillage(village);
    recipientIds.remove(senderUserId);
    if (recipientIds.isEmpty) return;

    final title = 'Important: $roomName';
    final body = messagePreview != null && messagePreview.isNotEmpty
        ? (messagePreview.length > 200
            ? '${messagePreview.substring(0, 200)}...'
            : messagePreview)
        : 'A new important message was posted in community chat.';

    for (var i = 0; i < recipientIds.length; i += _maxBatch) {
      final end = min(i + _maxBatch, recipientIds.length);
      final slice = recipientIds.sublist(i, end);
      final batch = _firestore.batch();
      for (final uid in slice) {
        final ref = _firestore.collection('notifications').doc();
        batch.set(ref, {
          'userId': uid,
          'type': 'community_important',
          'title': title,
          'message': body,
          'actionRoute': '/community/chat',
          'actionExtra': {
            'roomName': roomName,
          },
          'isRead': false,
          'createdAt': Timestamp.now(),
        });
      }
      await batch.commit();
    }
  }
}
