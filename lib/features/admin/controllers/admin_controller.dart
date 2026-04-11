import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/admin_user_model.dart';
import '../repositories/admin_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════════════════════════════════════

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(FirebaseFirestore.instance);
});

/// Search users by NIC
final searchUserByNicProvider = FutureProvider.family<AdminUserModel, String>(
  (ref, nic) async {
    final repository = ref.watch(adminRepositoryProvider);
    final result = await repository.searchUserByNic(nic).run();
    return result.fold(
      (error) => throw Exception(error),
      (user) => user,
    );
  },
);

/// Search users by phone number
final searchUserByPhoneProvider =
    FutureProvider.family<AdminUserModel, String>(
  (ref, phone) async {
    final repository = ref.watch(adminRepositoryProvider);
    final result = await repository.searchUserByPhone(phone).run();
    return result.fold(
      (error) => throw Exception(error),
      (user) => user,
    );
  },
);

/// Search users by name (partial, case-insensitive)
final searchUsersByNameProvider =
    FutureProvider.family<List<AdminUserModel>, String>(
  (ref, nameQuery) async {
    final repository = ref.watch(adminRepositoryProvider);
    final result = await repository.searchUsersByName(nameQuery).run();
    return result.fold(
      (error) => throw Exception(error),
      (users) => users,
    );
  },
);

/// Get a single user by UID
final getUserByUidProvider = FutureProvider.family<AdminUserModel, String>(
  (ref, uid) async {
    final repository = ref.watch(adminRepositoryProvider);
    final result = await repository.getUserByUid(uid).run();
    return result.fold(
      (error) => throw Exception(error),
      (user) => user,
    );
  },
);

/// Check if NIC is already registered
final nicExistsProvider = FutureProvider.family<bool, String>(
  (ref, nic) async {
    final repository = ref.watch(adminRepositoryProvider);
    final result = await repository.nicExists(nic).run();
    return result.fold(
      (error) => throw Exception(error),
      (exists) => exists,
    );
  },
);

/// Check if email is already registered
final emailExistsProvider = FutureProvider.family<bool, String>(
  (ref, email) async {
    final repository = ref.watch(adminRepositoryProvider);
    final result = await repository.emailExists(email).run();
    return result.fold(
      (error) => throw Exception(error),
      (exists) => exists,
    );
  },
);

/// Mutation: Update user role
final updateUserRoleProvider = FutureProvider.family<
    void,
    ({
      String uid,
      String newRole,
    })>((ref, params) async {
  final repository = ref.watch(adminRepositoryProvider);
  final result = await repository.updateUserRole(params.uid, params.newRole).run();
  return result.fold(
    (error) => throw Exception(error),
    (_) => null,
  );
});

/// Mutation: Update user account status
final updateUserAccountStatusProvider = FutureProvider.family<
    void,
    ({
      String uid,
      String status,
    })>((ref, params) async {
  final repository = ref.watch(adminRepositoryProvider);
  final result = await repository
      .updateUserAccountStatus(params.uid, params.status)
      .run();
  return result.fold(
    (error) => throw Exception(error),
    (_) => null,
  );
});

/// Mutation: Batch update user role and status
final updateUserRoleAndStatusProvider = FutureProvider.family<
    void,
    ({
      String uid,
      String newRole,
      String status,
    })>((ref, params) async {
  final repository = ref.watch(adminRepositoryProvider);
  final result = await repository
      .updateUserRoleAndStatus(
        params.uid,
        params.newRole,
        params.status,
      )
      .run();
  return result.fold(
    (error) => throw Exception(error),
    (_) => null,
  );
});

/// Get user count by role (useful for dashboard metrics)
final getUserCountByRoleProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  final result = await repository.getUserCountByRole().run();
  return result.fold(
    (error) => throw Exception(error),
    (counts) => counts,
  );
});
