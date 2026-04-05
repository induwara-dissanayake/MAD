import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String userId;
  final String documentType;
  final String fullName;
  final String nic;
  final String address;
  final String reason;
  final String status;
  final DateTime submittedAt;
  final String? rejectionReason;
  final String? certificateUrl;
  final Map<String, String>? formData;
  final List<String>? requiredFields;

  RequestModel({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.fullName,
    required this.nic,
    required this.address,
    required this.reason,
    required this.status,
    required this.submittedAt,
    this.rejectionReason,
    this.certificateUrl,
    this.formData,
    this.requiredFields,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'documentType': documentType,
      'fullName': fullName,
      'nic': nic,
      'address': address,
      'reason': reason,
      'status': status,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'rejectionReason': rejectionReason,
      'certificateUrl': certificateUrl,
      'formData': formData,
      'requiredFields': requiredFields,
    };
  }

  factory RequestModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? date;
    if (map['submittedAt'] is Timestamp) {
      date = (map['submittedAt'] as Timestamp).toDate();
    } else if (map['submittedAt'] is String) {
      date = DateTime.tryParse(map['submittedAt']);
    }

    return RequestModel(
      id: id,
      userId: map['userId'] ?? '',
      documentType: map['documentType'] ?? '',
      fullName: map['fullName'] ?? '',
      nic: map['nic'] ?? '',
      address: map['address'] ?? '',
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'Pending',
      submittedAt: date ?? DateTime.now(),
      rejectionReason: map['rejectionReason'],
      certificateUrl: map['certificateUrl'],
      formData: (map['formData'] as Map?)?.map(
        (key, value) => MapEntry('$key', '$value'),
      ),
      requiredFields: (map['requiredFields'] as List?)
          ?.map((e) => '$e')
          .toList(),
    );
  }
}
