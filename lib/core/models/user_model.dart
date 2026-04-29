import 'package:cloud_firestore/cloud_firestore.dart';

/// Member type for the village connect app.
enum MemberType {
  /// A brand-new resident to the village (created by admin-resident).
  newResident,

  /// A family member of an existing registered resident.
  familyMember,

  /// A rental occupant in an existing resident's property.
  rental,
}

extension MemberTypeX on MemberType {
  String get label {
    switch (this) {
      case MemberType.newResident:
        return 'Resident';
      case MemberType.familyMember:
        return 'Family Member';
      case MemberType.rental:
        return 'Rental';
    }
  }

  static MemberType fromString(String? value) {
    switch (value) {
      case 'family_member':
        return MemberType.familyMember;
      case 'rental':
        return MemberType.rental;
      default:
        return MemberType.newResident;
    }
  }

  String get key {
    switch (this) {
      case MemberType.familyMember:
        return 'family_member';
      case MemberType.rental:
        return 'rental';
      default:
        return 'new_resident';
    }
  }
}

class UserModel {
  final String uid;
  final String fullName;
  final String nic;
  final String phone;
  final String email; // Real email for sending credentials
  final String address;
  final String village;
  final String district;
  final String
  role; // citizen | admin_resident | admin | gn_officer | committee
  final String
  accountStatus; // pending_first_login | active | inactive | suspended
  final Map<String, bool> capabilities;
  final MemberType memberType;
  final String? relationship;
  final bool hasSystemAccess;
  final String? createdByUid; // UID of the resident/admin who created this user
  final DateTime createdAt;
  final String? photoURL;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.nic,
    required this.phone,
    required this.email,
    required this.address,
    required this.village,
    required this.district,
    this.role = 'citizen',
    this.accountStatus = 'pending_first_login',
    Map<String, bool>? capabilities,
    this.memberType = MemberType.newResident,
    this.relationship,
    this.hasSystemAccess = true,
    this.createdByUid,
    required this.createdAt,
    this.photoURL,
  }) : capabilities =
           capabilities ??
           const {
             'isCommitteeMember': false,
             'canModerateCommunity': false,
             'canManageIncidents': false,
             'canPublishNotices': false,
             'canAccessAdminDashboard': false,
           };

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'nic': nic,
      'phone': phone,
      'email': email,
      'address': address,
      'village': village,
      'district': district,
      'role': role,
      'accountStatus': accountStatus,
      'capabilities': capabilities,
      'memberType': memberType.key,
      'relationship': relationship,
      'hasSystemAccess': hasSystemAccess,
      'createdByUid': createdByUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(createdAt),
      'fullNameLower': fullName.toLowerCase(),
      'photoURL': photoURL,
    };
  }

  static Map<String, bool> _parseCapabilities(dynamic value, String role) {
    final defaults = <String, bool>{
      'isCommitteeMember': role == 'committee',
      'canModerateCommunity': role == 'committee' || role == 'gn_officer',
      'canManageIncidents': role == 'committee' || role == 'gn_officer',
      'canPublishNotices': role == 'gn_officer',
      'canAccessAdminDashboard': role == 'admin' || role == 'super_admin',
    };

    if (value is Map) {
      for (final entry in value.entries) {
        defaults[entry.key.toString()] = entry.value == true;
      }
    }
    return defaults;
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    DateTime? date;
    if (map['createdAt'] is Timestamp) {
      date = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      date = DateTime.tryParse(map['createdAt'] as String);
    }

    return UserModel(
      uid: uid,
      fullName: map['fullName'] as String? ?? '',
      nic: map['nic'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      village: map['village'] as String? ?? '',
      district: map['district'] as String? ?? '',
      role: map['role'] as String? ?? 'citizen',
      accountStatus: map['accountStatus'] as String? ?? 'active',
      capabilities: _parseCapabilities(
        map['capabilities'],
        map['role'] as String? ?? 'citizen',
      ),
      memberType: MemberTypeX.fromString(map['memberType'] as String?),
      relationship: map['relationship'] as String?,
      hasSystemAccess: map['hasSystemAccess'] as bool? ?? true,
      createdByUid: map['createdByUid'] as String?,
      createdAt: date ?? DateTime.now(),
      photoURL: map['photoURL'] as String?,
    );
  }
}
