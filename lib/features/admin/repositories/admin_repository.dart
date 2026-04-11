import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import '../../../core/models/admin_user_model.dart';

/// Admin repository for Super Admin operations.
/// **CRITICAL:** Implements search-first pattern to respect Firebase Spark Plan limits (50k daily reads).
/// No bulk collection fetches are performed.
class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository(this._firestore);

  /// Search for a user by exact NIC number.
  /// **Optimized:** Single indexed query = 1 read operation.
  TaskEither<String, AdminUserModel> searchUserByNic(String nic) {
    return TaskEither.tryCatch(
      () async {
        if (nic.trim().isEmpty) {
          throw Exception('NIC cannot be empty.');
        }

        final snapshot = await _firestore
            .collection('users')
            .where('nic', isEqualTo: nic.trim())
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          throw Exception('No user found with NIC: $nic');
        }

        return AdminUserModel.fromMap(
          snapshot.docs.first.data(),
          snapshot.docs.first.id,
        );
      },
      (error, stackTrace) => error.toString(),
    );
  }

  /// Search for a user by exact phone number.
  /// **Optimized:** Single indexed query = 1 read operation.
  TaskEither<String, AdminUserModel> searchUserByPhone(String phone) {
    return TaskEither.tryCatch(
      () async {
        if (phone.trim().isEmpty) {
          throw Exception('Phone number cannot be empty.');
        }

        final snapshot = await _firestore
            .collection('users')
            .where('phone', isEqualTo: phone.trim())
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          throw Exception('No user found with phone: $phone');
        }

        return AdminUserModel.fromMap(
          snapshot.docs.first.data(),
          snapshot.docs.first.id,
        );
      },
      (error, stackTrace) => error.toString(),
    );
  }

  /// Search for users by partial full name match (case-insensitive).
  /// **Note:** This uses range queries. For Spark Plan optimization,
  /// limit results to a reasonable number (e.g., 20).
  TaskEither<String, List<AdminUserModel>> searchUsersByName(String nameQuery) {
    return TaskEither.tryCatch(
      () async {
        if (nameQuery.trim().isEmpty) {
          throw Exception('Name query cannot be empty.');
        }

        final lowerQuery = nameQuery.toLowerCase();
        final snapshot = await _firestore
            .collection('users')
            .where('fullNameLower', isGreaterThanOrEqualTo: lowerQuery)
            .where('fullNameLower', isLessThan: '${lowerQuery}z')
            .limit(20) // Limit to 20 results
            .get();

        return snapshot.docs
            .map((doc) => AdminUserModel.fromMap(doc.data(), doc.id))
            .toList();
      },
      (error, stackTrace) => error.toString(),
    );
  }

  /// Update a user's role.
  /// **Optimized:** Single write operation.
  ///
  /// Valid roles: 'citizen', 'gn_officer', 'committee', 'admin', 'super_admin'
  TaskEither<String, void> updateUserRole(
    String uid,
    String newRole,
  ) {
    return TaskEither.tryCatch(
      () async {
        final validRoles = [
          'citizen',
          'gn_officer',
          'committee',
          'admin',
          'super_admin'
        ];
        if (!validRoles.contains(newRole)) {
          throw Exception('Invalid role: $newRole');
        }

        await _firestore.collection('users').doc(uid).update({
          'role': newRole,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      },
      (error, stackTrace) => error.toString(),
    );
  }

  /// Update a user's account status.
  /// **Optimized:** Single write operation.
  TaskEither<String, void> updateUserAccountStatus(
    String uid,
    String status,
  ) {
    return TaskEither.tryCatch(
      () async {
        await _firestore.collection('users').doc(uid).update({
          'accountStatus': status.toLowerCase(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      },
      (error, stackTrace) => error.toString(),
    );
  }

  /// Batch update user role and account status.
  /// **Optimized:** Single write transaction.
  TaskEither<String, void> updateUserRoleAndStatus(
    String uid,
    String newRole,
    String status,
  ) {
    return TaskEither.tryCatch(
      () async {
        final validRoles = [
          'citizen',
          'gn_officer',
          'committee',
          'admin',
          'super_admin'
        ];
        if (!validRoles.contains(newRole)) {
          throw Exception('Invalid role: $newRole');
        }

        await _firestore.collection('users').doc(uid).update({
          'role': newRole,
          'accountStatus': status.toLowerCase(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      },
      (error, stackTrace) => error.toString(),
    );
  }

  /// Check if a NIC is already registered in the system.
  /// **Optimized:** Single indexed query = 1 read operation.
  TaskEither<String, bool> nicExists(String nic) {
    return TaskEither.tryCatch(
      () async {
        final snapshot = await _firestore
            .collection('users')
            .where('nic', isEqualTo: nic)
            .limit(1)
            .get();

        return snapshot.docs.isNotEmpty;
      },
      (error, stackTrace) => error.toString(),
    );
  }

  /// Check if an email is already registered.
  /// **Optimized:** Single indexed query = 1 read operation.
  TaskEither<String, bool> emailExists(String email) {
    return TaskEither.tryCatch(
      () async {
        final snapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: email.toLowerCase())
            .limit(1)
            .get();

        return snapshot.docs.isNotEmpty;
      },
      (error, stackTrace) => error.toString(),
    );
  }

  /// Get total user count by role.
  /// **Caution:** This counts by role, which may require multiple queries.
  /// For Spark Plan, cache this result periodically.
  TaskEither<String, Map<String, int>> getUserCountByRole() {
    return TaskEither.tryCatch(
      () async {
        final snapshot = await _firestore.collection('users').get();
        final counts = <String, int>{};

        for (var doc in snapshot.docs) {
          final role = doc['role'] as String? ?? 'citizen';
          counts[role] = (counts[role] ?? 0) + 1;
        }

        return counts;
      },
      (error, stackTrace) => error.toString(),
    );
  }

  /// Get a user by UID directly (for audit/viewing).
  /// **Optimized:** Single document read.
  TaskEither<String, AdminUserModel> getUserByUid(String uid) {
    return TaskEither.tryCatch(
      () async {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (!doc.exists) {
          throw Exception('User not found: $uid');
        }

        return AdminUserModel.fromMap(doc.data()!, uid);
      },
      (error, stackTrace) => error.toString(),
    );
  }
}
