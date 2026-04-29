import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/community_post_model.dart';
import '../../../core/services/notification_service.dart';

final communityPostRepositoryProvider = Provider<CommunityPostRepository>((
  ref,
) {
  return CommunityPostRepository(
    FirebaseFirestore.instance,
    ref.watch(notificationServiceProvider),
  );
});

final approvedCommunityPostsProvider = StreamProvider<List<CommunityPostModel>>(
  (ref) {
    return ref.watch(communityPostRepositoryProvider).watchApprovedPosts();
  },
);

final pendingCommunityPostsProvider = StreamProvider<List<CommunityPostModel>>((
  ref,
) {
  return ref.watch(communityPostRepositoryProvider).watchPendingPosts();
});

class CommunityPostRepository {
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  CommunityPostRepository(this._firestore, this._notificationService);

  Future<String> createPost(CommunityPostModel post) async {
    final doc = await _firestore
        .collection('community_posts')
        .add(post.toMap());
    await _notifyModerators(doc.id, post);
    return doc.id;
  }

  Stream<List<CommunityPostModel>> watchApprovedPosts() {
    return _firestore
        .collection('community_posts')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map(_mapSortedPosts);
  }

  Stream<List<CommunityPostModel>> watchPendingPosts() {
    return _firestore
        .collection('community_posts')
        .where('status', isEqualTo: 'pending_moderation')
        .snapshots()
        .map(_mapSortedPosts);
  }

  Future<void> approvePost({
    required CommunityPostModel post,
    required String moderatorUid,
  }) async {
    await _firestore.collection('community_posts').doc(post.id).update({
      'status': 'approved',
      'moderatedBy': moderatorUid,
      'moderatedAt': FieldValue.serverTimestamp(),
    });
    await _notificationService.sendNotification(
      userId: post.userId,
      type: 'community_moderation',
      title: 'Community post approved',
      message:
          'Your post "${post.title}" is now visible in the community feed.',
      relatedId: post.id,
      actionRoute: '/community',
    );
  }

  Future<void> rejectPost({
    required CommunityPostModel post,
    required String moderatorUid,
    String? reason,
  }) async {
    await _firestore.collection('community_posts').doc(post.id).update({
      'status': 'removed',
      'moderatedBy': moderatorUid,
      'moderatedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
    });
    await _notificationService.sendNotification(
      userId: post.userId,
      type: 'community_moderation',
      title: 'Community post removed',
      message: reason == null || reason.trim().isEmpty
          ? 'Your post "${post.title}" was not approved.'
          : 'Your post "${post.title}" was not approved. Reason: $reason',
      relatedId: post.id,
      actionRoute: '/community',
    );
  }

  List<CommunityPostModel> _mapSortedPosts(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final posts = snapshot.docs
        .map((doc) => CommunityPostModel.fromMap(doc.data(), doc.id))
        .toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<void> _notifyModerators(String postId, CommunityPostModel post) async {
    final moderators = await _firestore
        .collection('users')
        .where('role', whereIn: ['gn_officer', 'admin', 'committee'])
        .get();

    final notified = <String>{};
    for (final doc in moderators.docs) {
      notified.add(doc.id);
      await _notificationService.sendNotification(
        userId: doc.id,
        type: 'community_moderation',
        title: 'New community post pending',
        message: '${post.authorName} submitted "${post.title}" for moderation.',
        relatedId: postId,
        actionRoute: '/community/moderation',
      );
    }

    final capabilityModerators = await _firestore
        .collection('users')
        .where('capabilities.canModerateCommunity', isEqualTo: true)
        .get();
    for (final doc in capabilityModerators.docs) {
      if (!notified.add(doc.id)) continue;
      await _notificationService.sendNotification(
        userId: doc.id,
        type: 'community_moderation',
        title: 'New community post pending',
        message: '${post.authorName} submitted "${post.title}" for moderation.',
        relatedId: postId,
        actionRoute: '/community/moderation',
      );
    }
  }
}
