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
      .limit(100)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => AdminUserModel.fromMap(doc.data(), doc.id))
            .toList();
      });
});

// ═══════════════════════════════════════════════════════════════════════════
// Request Metrics Providers
// ═══════════════════════════════════════════════════════════════════════════

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
