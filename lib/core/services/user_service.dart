import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(FirebaseFirestore.instance);
});

class UserService {
  final FirebaseFirestore _firestore;

  UserService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Create user profile document keyed by Firebase Auth UID.
  Future<void> createUserProfile(UserModel user) async {
    await _usersCollection.doc(user.uid).set(user.toMap());
  }

  /// Stream a single user profile.
  Stream<UserModel?> getUserProfile(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Fetch a single user profile once.
  Future<UserModel?> getUserProfileOnce(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  /// Check if logged-in user has admin permission (can create new residents).
  Future<bool> isAdmin(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) return false;
      final role = doc.data()?['role'] as String? ?? 'citizen';
      return role == 'admin_resident' || role == 'gn_officer';
    } catch (_) {
      return false;
    }
  }

  /// Stream all family members / rental users created by [creatorUid].
  Stream<List<UserModel>> streamHouseholdMembers(String creatorUid) {
    return _usersCollection
        .where('createdByUid', isEqualTo: creatorUid)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  /// Check if a NIC is already registered.
  Future<bool> isNicRegistered(String nic) async {
    try {
      final query = await _usersCollection
          .where('nic', isEqualTo: nic)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Update the user's role (admin only action).
  Future<void> updateRole(String uid, String newRole) async {
    await _usersCollection.doc(uid).update({'role': newRole});
  }

  /// Update editable personal information fields.
  Future<void> updatePersonalInformation({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    await _usersCollection.doc(uid).update({
      'fullName': fullName,
      'email': email,
      'phone': phone,
    });
  }

  /// Stream all residents (for admin user management).
  Stream<List<UserModel>> streamAllUsers() {
    return _usersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList(),
        );
  }
}
