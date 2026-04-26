import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final String? requestId;
  final String? relatedId;
  final String? actionRoute;
  final Map<String, dynamic> actionExtra;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.requestId,
    this.relatedId,
    this.actionRoute,
    this.actionExtra = const {},
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
      'relatedId': relatedId,
      'actionRoute': actionRoute,
      'actionExtra': actionExtra,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static Map<String, dynamic> _parseActionExtra(dynamic raw) {
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
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
      requestId: map['requestId'] as String?,
      relatedId: map['relatedId'] as String?,
      actionRoute: map['actionRoute'] as String?,
      actionExtra: _parseActionExtra(map['actionExtra']),
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
    String? relatedId,
    String? actionRoute,
    Map<String, dynamic>? actionExtra,
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
      relatedId: relatedId ?? this.relatedId,
      actionRoute: actionRoute ?? this.actionRoute,
      actionExtra: actionExtra ?? this.actionExtra,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
