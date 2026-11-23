import 'package:uuid/uuid.dart';

enum MessageRole { user, assistant, system }

enum MessageStatus { pending, streaming, complete, error }

class ChatMessage {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;

  ChatMessage({
    String? id,
    required this.conversationId,
    required this.role,
    required this.content,
    DateTime? createdAt,
    this.status = MessageStatus.complete,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  ChatMessage copyWith({String? content, MessageStatus? status}) => ChatMessage(
    id: id,
    conversationId: conversationId,
    role: role,
    content: content ?? this.content,
    createdAt: createdAt,
    status: status ?? this.status,
  );
}
