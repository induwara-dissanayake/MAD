import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/admin_user_model.dart';
import '../../../core/models/request_model.dart';
import '../../../core/models/notice_model.dart';
import '../repositories/admin_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════════════════════════════════════

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(FirebaseFirestore.instance);
});

/// Search users by NIC
final searchUserByNicProvider = FutureProvider.family<AdminUserModel, String>((
  ref,
  nic,
) async {
  final repository = ref.watch(adminRepositoryProvider);
  final result = await repository.searchUserByNic(nic).run();
  return result.fold((error) => throw Exception(error), (user) => user);
});

/// Search users by phone number
final searchUserByPhoneProvider = FutureProvider.family<AdminUserModel, String>(
  (ref, phone) async {
    final repository = ref.watch(adminRepositoryProvider);
    final result = await repository.searchUserByPhone(phone).run();
    return result.fold((error) => throw Exception(error), (user) => user);
  },
);

/// Search users by name (partial, case-insensitive)
final searchUsersByNameProvider =
    FutureProvider.family<List<AdminUserModel>, String>((ref, nameQuery) async {
      final repository = ref.watch(adminRepositoryProvider);
      final result = await repository.searchUsersByName(nameQuery).run();
      return result.fold((error) => throw Exception(error), (users) => users);
    });

/// Get a single user by UID
final getUserByUidProvider = FutureProvider.family<AdminUserModel, String>((
  ref,
  uid,
) async {
  final repository = ref.watch(adminRepositoryProvider);
  final result = await repository.getUserByUid(uid).run();
  return result.fold((error) => throw Exception(error), (user) => user);
});

/// Check if NIC is already registered
final nicExistsProvider = FutureProvider.family<bool, String>((ref, nic) async {
  final repository = ref.watch(adminRepositoryProvider);
  final result = await repository.nicExists(nic).run();
  return result.fold((error) => throw Exception(error), (exists) => exists);
});

/// Check if email is already registered
final emailExistsProvider = FutureProvider.family<bool, String>((
  ref,
  email,
) async {
  final repository = ref.watch(adminRepositoryProvider);
  final result = await repository.emailExists(email).run();
  return result.fold((error) => throw Exception(error), (exists) => exists);
});

/// Mutation: Update user role
final updateUserRoleProvider =
    FutureProvider.family<void, ({String uid, String newRole})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(adminRepositoryProvider);
      final result = await repository
          .updateUserRole(params.uid, params.newRole)
          .run();
      return result.fold((error) => throw Exception(error), (_) => null);
    });

/// Mutation: Update user account status
final updateUserAccountStatusProvider =
    FutureProvider.family<void, ({String uid, String status})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(adminRepositoryProvider);
      final result = await repository
          .updateUserAccountStatus(params.uid, params.status)
          .run();
      return result.fold((error) => throw Exception(error), (_) => null);
    });

/// Mutation: Update user capability flags.
final updateUserCapabilitiesProvider =
    FutureProvider.family<void, ({String uid, Map<String, bool> capabilities})>(
      (ref, params) async {
        final repository = ref.watch(adminRepositoryProvider);
        final result = await repository
            .updateUserCapabilities(params.uid, params.capabilities)
            .run();
        return result.fold((error) => throw Exception(error), (_) => null);
      },
    );

/// Mutation: Batch update user role and status
final updateUserRoleAndStatusProvider =
    FutureProvider.family<void, ({String uid, String newRole, String status})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(adminRepositoryProvider);
      final result = await repository
          .updateUserRoleAndStatus(params.uid, params.newRole, params.status)
          .run();
      return result.fold((error) => throw Exception(error), (_) => null);
    });

/// Get user count by role (useful for dashboard metrics)
final getUserCountByRoleProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final repository = ref.watch(adminRepositoryProvider);
  final result = await repository.getUserCountByRole().run();
  return result.fold((error) => throw Exception(error), (counts) => counts);
});

/// Stream current users for user management listing.
final currentUsersProvider = StreamProvider<List<AdminUserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => AdminUserModel.fromMap(doc.data(), doc.id))
            .toList();
      });
});

/// Spark-safe aggregate stats. Keep this document updated during write flows
/// or seed it from Firebase console while running on the free tier.
final systemStatsProvider = StreamProvider<Map<String, int>>((ref) {
  return FirebaseFirestore.instance
      .collection('system_stats')
      .doc('global')
      .snapshots()
      .map((doc) {
        final data = doc.data() ?? const <String, dynamic>{};
        int intValue(String key) {
          final value = data[key];
          if (value is int) return value;
          if (value is num) return value.toInt();
          return 0;
        }

        return {
          'totalUsers': intValue('totalUsers'),
          'totalCitizens': intValue('totalCitizens'),
          'totalGnOfficers': intValue('totalGnOfficers'),
          'totalCommitteeMembers': intValue('totalCommitteeMembers'),
          'pendingRequests': intValue('pendingRequests'),
          'totalRequests': intValue('totalRequests'),
          'publishedNotices': intValue('publishedNotices'),
          'openIncidents': intValue('openIncidents'),
          'pendingCommunityPosts': intValue('pendingCommunityPosts'),
        };
      });
});

// ═══════════════════════════════════════════════════════════════════════════
// Request Metrics Providers
// ═══════════════════════════════════════════════════════════════════════════

/// Live dashboard counters for the admin landing page.
///
/// The analytics screen intentionally reads system_stats/global, but the
/// dashboard should still show current data when that aggregate document has
/// not been seeded or maintained yet.
final adminDashboardStatsProvider = StreamProvider<Map<String, int>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final controller = StreamController<Map<String, int>>();

  QuerySnapshot<Map<String, dynamic>>? usersSnapshot;
  QuerySnapshot<Map<String, dynamic>>? requestsSnapshot;
  QuerySnapshot<Map<String, dynamic>>? noticesSnapshot;
  QuerySnapshot<Map<String, dynamic>>? incidentsSnapshot;
  QuerySnapshot<Map<String, dynamic>>? communityPostsSnapshot;
  DocumentSnapshot<Map<String, dynamic>>? aggregateSnapshot;

  void emitIfReady() {
    if (controller.isClosed ||
        usersSnapshot == null ||
        requestsSnapshot == null ||
        noticesSnapshot == null ||
        incidentsSnapshot == null ||
        communityPostsSnapshot == null ||
        aggregateSnapshot == null) {
      return;
    }

    final stats = _buildAdminDashboardStats(
      users: usersSnapshot!.docs.map((doc) => doc.data()),
      requests: requestsSnapshot!.docs.map((doc) => doc.data()),
      notices: noticesSnapshot!.docs.map((doc) => doc.data()),
      incidents: incidentsSnapshot!.docs.map((doc) => doc.data()),
      communityPosts: communityPostsSnapshot!.docs.map((doc) => doc.data()),
      aggregate: aggregateSnapshot!.data(),
    );
    controller.add(stats);
  }

  final subscriptions = <StreamSubscription>[
    firestore.collection('users').snapshots().listen((snapshot) {
      usersSnapshot = snapshot;
      emitIfReady();
    }, onError: controller.addError),
    firestore.collection('requests').snapshots().listen((snapshot) {
      requestsSnapshot = snapshot;
      emitIfReady();
    }, onError: controller.addError),
    firestore.collection('notices').snapshots().listen((snapshot) {
      noticesSnapshot = snapshot;
      emitIfReady();
    }, onError: controller.addError),
    firestore.collection('incidents').snapshots().listen((snapshot) {
      incidentsSnapshot = snapshot;
      emitIfReady();
    }, onError: controller.addError),
    firestore.collection('community_posts').snapshots().listen((snapshot) {
      communityPostsSnapshot = snapshot;
      emitIfReady();
    }, onError: controller.addError),
    firestore.collection('system_stats').doc('global').snapshots().listen((
      snapshot,
    ) {
      aggregateSnapshot = snapshot;
      emitIfReady();
    }, onError: controller.addError),
  ];

  ref.onDispose(() async {
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    await controller.close();
  });

  return controller.stream;
});

Map<String, int> _buildAdminDashboardStats({
  required Iterable<Map<String, dynamic>> users,
  required Iterable<Map<String, dynamic>> requests,
  required Iterable<Map<String, dynamic>> notices,
  required Iterable<Map<String, dynamic>> incidents,
  required Iterable<Map<String, dynamic>> communityPosts,
  Map<String, dynamic>? aggregate,
}) {
  final userList = users.toList();
  final requestList = requests.toList();
  final noticeList = notices.toList();
  final incidentList = incidents.toList();
  final communityPostList = communityPosts.toList();

  final totalCitizens = userList.where((user) {
    final role = _normalizedString(user['role']);
    return role == 'citizen' || role == 'admin_resident';
  }).length;
  final totalGnOfficers = userList
      .where((user) => _normalizedString(user['role']) == 'gn_officer')
      .length;
  final totalCommitteeMembers = userList
      .where((user) => _normalizedString(user['role']) == 'committee')
      .length;
  final pendingRequests = requestList.where((request) {
    return _normalizedString(request['status']) == 'pending';
  }).length;
  final publishedNotices = noticeList.where((notice) {
    final status = _normalizedString(notice['status']);
    return status.isEmpty || status == 'published' || status == 'sent';
  }).length;
  final openIncidents = incidentList.where((incident) {
    return _normalizedString(incident['status']) != 'resolved';
  }).length;
  final pendingCommunityPosts = communityPostList.where((post) {
    return _normalizedString(post['status']) == 'pending_moderation';
  }).length;

  return {
    'totalUsers': userList.length,
    'totalCitizens': totalCitizens,
    'totalGnOfficers': totalGnOfficers,
    'totalCommitteeMembers': totalCommitteeMembers,
    'pendingRequests': pendingRequests,
    'totalRequests': requestList.length,
    'publishedNotices': publishedNotices,
    'openIncidents': openIncidents,
    'pendingCommunityPosts': pendingCommunityPosts,
    'aggregateOpenIncidents': _aggregateInt(aggregate, 'openIncidents'),
    'aggregatePendingCommunityPosts': _aggregateInt(
      aggregate,
      'pendingCommunityPosts',
    ),
  };
}

String _normalizedString(dynamic value) {
  return (value ?? '').toString().trim().toLowerCase();
}

int _aggregateInt(Map<String, dynamic>? data, String key) {
  final value = data?[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}

/// Get all requests (real-time)
final allRequestsProvider = StreamProvider<List<RequestModel>>((ref) {
  return FirebaseFirestore.instance.collection('requests').snapshots().map((
    snapshot,
  ) {
    return snapshot.docs
        .map((doc) => RequestModel.fromMap(doc.data(), doc.id))
        .toList();
  });
});

/// Get request metrics - pending, approved this month, rejected this month
final requestMetricsProvider =
    StreamProvider<({int pending, int approved, int rejected, int total})>((
      ref,
    ) {
      return FirebaseFirestore.instance
          .collection('requests')
          .snapshots()
          .asyncMap((snapshot) async {
            final requests = snapshot.docs;

            int pending = 0;
            int approved = 0;
            int rejected = 0;

            final now = DateTime.now();
            final monthStart = DateTime(now.year, now.month, 1);

            for (final doc in requests) {
              final status = (doc['status'] as String?)?.toLowerCase();

              if (status == 'pending') {
                pending++;
              } else if (status == 'approved') {
                final processedAt = doc['processedAt'] as Timestamp?;
                if (processedAt != null &&
                    processedAt.toDate().isAfter(monthStart)) {
                  approved++;
                }
              } else if (status == 'rejected') {
                final processedAt = doc['processedAt'] as Timestamp?;
                if (processedAt != null &&
                    processedAt.toDate().isAfter(monthStart)) {
                  rejected++;
                }
              }
            }

            return (
              pending: pending,
              approved: approved,
              rejected: rejected,
              total: requests.length,
            );
          });
    });

// ═══════════════════════════════════════════════════════════════════════════
// Notice Providers
// ═══════════════════════════════════════════════════════════════════════════

/// Get all notices (real-time)
final allNoticesProvider = StreamProvider<List<NoticeModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('notices')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => NoticeModel.fromMap(doc.data(), doc.id))
            .toList();
      });
});

/// Get notice count
final noticeCountProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection('notices')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

/// Get all reviewed certificate requests for admin oversight.
final allCertificateRequestsProvider = StreamProvider<List<RequestModel>>((
  ref,
) {
  return FirebaseFirestore.instance.collection('certificaterq').snapshots().map(
    (snapshot) {
      return snapshot.docs
          .map((doc) => RequestModel.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    },
  );
});

/// Mutation: Delete a user profile and related Firestore records.
final deleteUserProvider = FutureProvider.family<void, String>((
  ref,
  uid,
) async {
  final repository = ref.watch(adminRepositoryProvider);
  final result = await repository.deleteUser(uid).run();
  return result.fold((error) => throw Exception(error), (_) => null);
});
