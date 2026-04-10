import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String type; // 'approval', 'rejection', 'info_request'
  final String title;
  final String message;
  final String? requestId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.requestId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'requestId': requestId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? date;
    if (map['createdAt'] is Timestamp) {
      date = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      date = DateTime.tryParse(map['createdAt']);
    }

    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'info',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      requestId: map['requestId'],
      isRead: map['isRead'] ?? false,
      createdAt: date ?? DateTime.now(),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    String? requestId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      requestId: requestId ?? this.requestId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
