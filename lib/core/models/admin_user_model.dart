import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Account status for admin user management.
enum AccountStatus {
  active,
  inactive,
  suspended,
}

extension AccountStatusX on AccountStatus {
  String get value {
    switch (this) {
      case AccountStatus.active:
        return 'Active';
      case AccountStatus.inactive:
        return 'Inactive';
      case AccountStatus.suspended:
        return 'Suspended';
    }
  }

  static AccountStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'inactive':
        return AccountStatus.inactive;
      case 'suspended':
        return AccountStatus.suspended;
      default:
        return AccountStatus.active;
    }
  }

  Color get statusColor {
    switch (this) {
      case AccountStatus.active:
        return const Color(0xFF4CAF50);
      case AccountStatus.inactive:
        return const Color(0xFFFFC107);
      case AccountStatus.suspended:
        return const Color(0xFFF44336);
    }
  }
}

/// Admin-focused user view for system admin management screens.
/// Designed for rapid role/status updates without exposing unnecessary fields.
class AdminUserModel {
  final String uid;
  final String fullName;
  final String nic;
  final String phone;
  final String email;
  final String address;
  final String village;
  final String role; // citizen | gn_officer | committee | admin
  final AccountStatus accountStatus;
  final DateTime createdAt;
  final DateTime? lastLogin;

  AdminUserModel({
    required this.uid,
    required this.fullName,
    required this.nic,
    required this.phone,
    required this.email,
    required this.address,
    required this.village,
    this.role = 'citizen',
    this.accountStatus = AccountStatus.active,
    required this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'accountStatus': accountStatus.value.toLowerCase(),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  factory AdminUserModel.fromMap(Map<String, dynamic> map, String uid) {
    DateTime? lastLogin;
    if (map['lastLogin'] is Timestamp) {
      lastLogin = (map['lastLogin'] as Timestamp).toDate();
    } else if (map['lastLogin'] is String) {
      lastLogin = DateTime.tryParse(map['lastLogin'] as String);
    }

    return AdminUserModel(
      uid: uid,
      fullName: map['fullName'] as String? ?? '',
      nic: map['nic'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      village: map['village'] as String? ?? '',
      role: map['role'] as String? ?? 'citizen',
      accountStatus:
          AccountStatusX.fromString(map['accountStatus'] as String?),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLogin: lastLogin,
    );
  }

  AdminUserModel copyWith({
    String? uid,
    String? fullName,
    String? nic,
    String? phone,
    String? email,
    String? address,
    String? village,
    String? role,
    AccountStatus? accountStatus,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return AdminUserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      nic: nic ?? this.nic,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      village: village ?? this.village,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
