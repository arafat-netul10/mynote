
import 'package:cloud_firestore/cloud_firestore.dart';

import 'base_model.dart';

class NoteModel extends BaseModel {
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reminderAt;

  const NoteModel({
    required super.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.reminderAt,
  });

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
      reminderAt: map['reminderAt'] == null
          ? null
          : _parseDate(map['reminderAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);

    throw FormatException('Invalid date value: $value');
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reminderAt': reminderAt == null
          ? null
          : Timestamp.fromDate(reminderAt!),
    };
  }

  NoteModel copyWith({
    String? title,
    String? description,
    DateTime? updatedAt,
    DateTime? reminderAt,
    bool clearReminder = false,
  }) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderAt:
      clearReminder ? null : reminderAt ?? this.reminderAt,
    );
  }
}
