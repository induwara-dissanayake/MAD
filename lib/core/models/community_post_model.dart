import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPostModel {
  final String id;
  final String userId;
  final String authorName;
  final String type;
  final String title;
  final String description;
  final String location;
  final String contact;
  final String status;
  final DateTime createdAt;
  final DateTime? moderatedAt;
  final String? moderatedBy;
  final String? rejectionReason;

  CommunityPostModel({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.type,
    required this.title,
    required this.description,
    required this.location,
    required this.contact,
    required this.status,
    required this.createdAt,
    this.moderatedAt,
    this.moderatedBy,
    this.rejectionReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'authorName': authorName,
      'type': type,
      'title': title,
      'description': description,
      'location': location,
      'contact': contact,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'moderatedAt': moderatedAt == null
          ? null
          : Timestamp.fromDate(moderatedAt!),
      'moderatedBy': moderatedBy,
      'rejectionReason': rejectionReason,
    };
  }

  factory CommunityPostModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? createdAt;
    if (map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      createdAt = DateTime.tryParse(map['createdAt'] as String);
    }

    DateTime? moderatedAt;
    if (map['moderatedAt'] is Timestamp) {
      moderatedAt = (map['moderatedAt'] as Timestamp).toDate();
    } else if (map['moderatedAt'] is String) {
      moderatedAt = DateTime.tryParse(map['moderatedAt'] as String);
    }

    return CommunityPostModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Citizen',
      type: map['type'] as String? ?? 'general',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? '',
      contact: map['contact'] as String? ?? '',
      status: map['status'] as String? ?? 'pending_moderation',
      createdAt: createdAt ?? DateTime.now(),
      moderatedAt: moderatedAt,
      moderatedBy: map['moderatedBy'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }
}
