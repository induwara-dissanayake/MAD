import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String nic;
  final String phone;
  final String address;
  final String village;
  final String district;
  final String? googleEmail;
  final String role;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.nic,
    required this.phone,
    required this.address,
    required this.village,
    required this.district,
    this.googleEmail,
    this.role = 'citizen',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'nic': nic,
      'phone': phone,
      'address': address,
      'village': village,
      'district': district,
      'googleEmail': googleEmail,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
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
      address: map['address'] as String? ?? '',
      village: map['village'] as String? ?? '',
      district: map['district'] as String? ?? '',
      googleEmail: map['googleEmail'] as String?,
      role: map['role'] as String? ?? 'citizen',
      createdAt: date ?? DateTime.now(),
    );
  }
}
