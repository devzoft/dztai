import 'package:uuid/uuid.dart';

class Conversation {
  final String id;
  final String title;
  final String modelId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  Conversation({
    String? id,
    required this.title,
    required this.modelId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Conversation copyWith({String? title, DateTime? updatedAt, bool? isPinned}) =>
      Conversation(
        id: id,
        title: title ?? this.title,
        modelId: modelId,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isPinned: isPinned ?? this.isPinned,
      );
}
