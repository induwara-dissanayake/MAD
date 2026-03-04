import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime date;
  final bool isVerified;
  final String? attachmentUrl;

  NoticeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.isVerified,
    this.attachmentUrl,
  });

  factory NoticeModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? date;
    if (map['date'] is Timestamp) {
      date = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is String) {
      date = DateTime.tryParse(map['date']);
    }

    return NoticeModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      date: date ?? DateTime.now(),
      isVerified: map['isVerified'] ?? false,
      attachmentUrl: map['attachmentUrl'],
    );
  }
}
