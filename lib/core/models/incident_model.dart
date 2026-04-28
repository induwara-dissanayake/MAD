import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentModel {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reporterNic;
  final String type;
  final String description;
  final String location;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? assignedTo;
  final String? responseNotes;

  IncidentModel({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reporterNic,
    required this.type,
    required this.description,
    required this.location,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.assignedTo,
    this.responseNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterNic': reporterNic,
      'type': type,
      'description': description,
      'location': location,
      'priority': priority,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'assignedTo': assignedTo,
      'responseNotes': responseNotes,
    };
  }

  factory IncidentModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? createdAt;
    if (map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      createdAt = DateTime.tryParse(map['createdAt'] as String);
    }

    DateTime? updatedAt;
    if (map['updatedAt'] is Timestamp) {
      updatedAt = (map['updatedAt'] as Timestamp).toDate();
    } else if (map['updatedAt'] is String) {
      updatedAt = DateTime.tryParse(map['updatedAt'] as String);
    }

    return IncidentModel(
      id: id,
      reporterId: map['reporterId'] as String? ?? '',
      reporterName: map['reporterName'] as String? ?? 'Citizen',
      reporterNic: map['reporterNic'] as String? ?? '',
      type: map['type'] as String? ?? 'Other',
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? '',
      priority: map['priority'] as String? ?? 'High',
      status: map['status'] as String? ?? 'Acknowledged',
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
      assignedTo: map['assignedTo'] as String?,
      responseNotes: map['responseNotes'] as String?,
    );
  }
}
