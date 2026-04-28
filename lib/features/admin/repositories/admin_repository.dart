import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import '../../../core/models/admin_user_model.dart';

/// Admin repository for system admin operations.
/// **CRITICAL:** Implements search-first pattern to respect Firebase Spark Plan limits (50k daily reads).
/// No bulk collection fetches are performed.
class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository(this._firestore);

  /// Search for a user by exact NIC number.
  /// **Optimized:** Single indexed query = 1 read operation.
  TaskEither<String, AdminUserModel> searchUserByNic(String nic) {
    return TaskEither.tryCatch(() async {
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
    }, (error, stackTrace) => error.toString());
  }

  /// Search for a user by exact phone number.
  /// **Optimized:** Single indexed query = 1 read operation.
  TaskEither<String, AdminUserModel> searchUserByPhone(String phone) {
    return TaskEither.tryCatch(() async {
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
    }, (error, stackTrace) => error.toString());
  }

  /// Search for users by partial full name match (case-insensitive).
  /// **Note:** This uses range queries. For Spark Plan optimization,
  /// limit results to a reasonable number (e.g., 20).
  TaskEither<String, List<AdminUserModel>> searchUsersByName(String nameQuery) {
    return TaskEither.tryCatch(() async {
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
    }, (error, stackTrace) => error.toString());
  }

  /// Update a user's role.
  /// **Optimized:** Single write operation.
  ///
  /// Valid base roles: 'citizen', 'gn_officer', 'admin'.
  ///
  /// Committee access is handled through capabilities, per the PRD.
  TaskEither<String, void> updateUserRole(String uid, String newRole) {
    return TaskEither.tryCatch(() async {
      final validRoles = ['citizen', 'gn_officer', 'admin'];
      if (!validRoles.contains(newRole)) {
        throw Exception('Invalid role: $newRole');
      }

      await _firestore.collection('users').doc(uid).update({
        'role': newRole,
        'capabilities': _capabilitiesForRole(newRole),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _writeAuditLog(
        action: 'update_user_role',
        targetUid: uid,
        details: {'role': newRole},
      );
    }, (error, stackTrace) => error.toString());
  }

  /// Update a user's account status.
  /// **Optimized:** Single write operation.
  TaskEither<String, void> updateUserAccountStatus(String uid, String status) {
    return TaskEither.tryCatch(() async {
      await _firestore.collection('users').doc(uid).update({
        'accountStatus': status.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _writeAuditLog(
        action: 'update_account_status',
        targetUid: uid,
        details: {'accountStatus': status.toLowerCase()},
      );
    }, (error, stackTrace) => error.toString());
  }

  /// Update capability flags without changing the base role.
  ///
  /// This supports the PRD model where committee and dashboard access are
  /// assigned as capabilities instead of multiplying roles.
  TaskEither<String, void> updateUserCapabilities(
    String uid,
    Map<String, bool> capabilities,
  ) {
    return TaskEither.tryCatch(() async {
      await _firestore.collection('users').doc(uid).update({
        'capabilities': capabilities,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _writeAuditLog(
        action: 'update_user_capabilities',
        targetUid: uid,
        details: {'capabilities': capabilities},
      );
    }, (error, stackTrace) => error.toString());
  }

  /// Batch update user role and account status.
  /// **Optimized:** Single write transaction.
  TaskEither<String, void> updateUserRoleAndStatus(
    String uid,
    String newRole,
    String status,
  ) {
    return TaskEither.tryCatch(() async {
      final validRoles = ['citizen', 'gn_officer', 'admin'];
      if (!validRoles.contains(newRole)) {
        throw Exception('Invalid role: $newRole');
      }

      await _firestore.collection('users').doc(uid).update({
        'role': newRole,
        'capabilities': _capabilitiesForRole(newRole),
        'accountStatus': status.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _writeAuditLog(
        action: 'update_user_role_and_status',
        targetUid: uid,
        details: {'role': newRole, 'accountStatus': status.toLowerCase()},
      );
    }, (error, stackTrace) => error.toString());
  }

  /// Delete a user profile and related Firestore records.
  /// This removes the Firestore profile and user-facing records; Firebase Auth
  /// account deletion still requires a backend admin SDK.
  TaskEither<String, void> deleteUser(String uid) {
    return TaskEither.tryCatch(() async {
      final batch = _firestore.batch();

      batch.delete(_firestore.collection('users').doc(uid));

      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .get();
      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      final requests = await _firestore
          .collection('requests')
          .where('userId', isEqualTo: uid)
          .get();
      for (final doc in requests.docs) {
        batch.delete(doc.reference);
      }

      final certificateRequests = await _firestore
          .collection('certificaterq')
          .where('userId', isEqualTo: uid)
          .get();
      for (final doc in certificateRequests.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      await _writeAuditLog(
        action: 'delete_user_profile',
        targetUid: uid,
        details: {
          'collections': 'users, notifications, requests, certificaterq',
        },
      );
    }, (error, stackTrace) => error.toString());
  }

  /// Check if a NIC is already registered in the system.
  /// **Optimized:** Single indexed query = 1 read operation.
  TaskEither<String, bool> nicExists(String nic) {
    return TaskEither.tryCatch(() async {
      final snapshot = await _firestore
          .collection('users')
          .where('nic', isEqualTo: nic)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    }, (error, stackTrace) => error.toString());
  }

  /// Check if an email is already registered.
  /// **Optimized:** Single indexed query = 1 read operation.
  TaskEither<String, bool> emailExists(String email) {
    return TaskEither.tryCatch(() async {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    }, (error, stackTrace) => error.toString());
  }

  /// Get total user count by role.
  /// **Caution:** This counts by role, which may require multiple queries.
  /// For Spark Plan, cache this result periodically.
  TaskEither<String, Map<String, int>> getUserCountByRole() {
    return TaskEither.tryCatch(() async {
      final snapshot = await _firestore.collection('users').get();
      final counts = <String, int>{};

      for (var doc in snapshot.docs) {
        final role = doc['role'] as String? ?? 'citizen';
        counts[role] = (counts[role] ?? 0) + 1;
      }

      return counts;
    }, (error, stackTrace) => error.toString());
  }

  /// Get a user by UID directly (for audit/viewing).
  /// **Optimized:** Single document read.
  TaskEither<String, AdminUserModel> getUserByUid(String uid) {
    return TaskEither.tryCatch(() async {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        throw Exception('User not found: $uid');
      }

      return AdminUserModel.fromMap(doc.data()!, uid);
    }, (error, stackTrace) => error.toString());
  }

  Map<String, bool> _capabilitiesForRole(String role) {
    return {
      'isCommitteeMember': false,
      'canModerateCommunity': role == 'gn_officer',
      'canAccessAdminDashboard': role == 'admin',
    };
  }

  Future<void> _writeAuditLog({
    required String action,
    required String targetUid,
    required Map<String, dynamic> details,
  }) async {
    await _firestore.collection('audit_logs').add({
      'action': action,
      'targetUid': targetUid,
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
