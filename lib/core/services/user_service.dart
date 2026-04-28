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

  Future<void> updatePersonalInformation({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'fullName': fullName,
      'fullNameLower': fullName.toLowerCase(),
      'email': email,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeFirstLoginProfile({
    required String uid,
    required String fullName,
    required String phone,
    required String address,
  }) async {
    await _usersCollection.doc(uid).update({
      'fullName': fullName.trim(),
      'fullNameLower': fullName.trim().toLowerCase(),
      'phone': phone.trim(),
      'address': address.trim(),
      'accountStatus': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
      'activatedAt': FieldValue.serverTimestamp(),
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
      final data = doc.data()!;
      final role = data['role'] as String? ?? 'citizen';
      final caps = data['capabilities'] as Map?;
      return role == 'admin_resident' ||
          role == 'gn_officer' ||
          role == 'admin' ||
          caps?['canAccessAdminDashboard'] == true;
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

  /// Stream household members visible from a profile.
  ///
  /// Household owners see members they created. A family/rental member sees
  /// other member profiles that share the same household owner.
  Stream<List<UserModel>> streamVisibleHouseholdMembers(UserModel profile) {
    final ownerUid = (profile.createdByUid != null &&
            profile.createdByUid!.trim().isNotEmpty &&
            profile.memberType != MemberType.newResident)
        ? profile.createdByUid!.trim()
        : profile.uid;

    return streamHouseholdMembers(ownerUid).map(
      (members) => members.where((member) => member.uid != profile.uid).toList(),
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

  /// All user document IDs in a village (for notification fan-out).
  Future<List<String>> getUserUidsInVillage(String village) async {
    if (village.isEmpty) return [];
    final q = await _usersCollection.where('village', isEqualTo: village).get();
    return q.docs.map((d) => d.id).toList();
  }

  /// GN officer, app admin, or super_admin — matches [firestore.rules] `isOfficialOrAdmin` intent.
  Future<bool> isOfficialOrAdminUser(String uid) async {
    final m = await getUserProfileOnce(uid);
    if (m == null) return false;
    final r = m.role;
    if (r == 'super_admin') return true;
    return r == 'gn_officer' ||
        r == 'admin' ||
        m.capabilities['canAccessAdminDashboard'] == true;
  }

  Future<bool> canModerateCommunity(String uid) async {
    final m = await getUserProfileOnce(uid);
    if (m == null) return false;
    return m.role == 'gn_officer' ||
        m.role == 'admin' ||
        m.role == 'committee' ||
        m.capabilities['canModerateCommunity'] == true;
  }
}
