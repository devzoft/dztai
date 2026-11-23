import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../../models/conversation.dart';
import '../../models/chat_message.dart';

class ConversationRepository {
  final AppDatabase _db;
  ConversationRepository(this._db);

  Future<List<Conversation>> getAll() async {
    final rows = await _db.select(_db.conversations).get();
    rows.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return rows.map(_toConversation).toList();
  }

  Future<Conversation> create(Conversation conversation) async {
    await _db
        .into(_db.conversations)
        .insert(
          ConversationsCompanion.insert(
            id: conversation.id,
            title: conversation.title,
            modelId: conversation.modelId,
            createdAt: conversation.createdAt.millisecondsSinceEpoch,
            updatedAt: conversation.updatedAt.millisecondsSinceEpoch,
            isPinned: Value(conversation.isPinned),
          ),
        );
    return conversation;
  }

  Future<void> update(Conversation conversation) async {
    await (_db.update(
      _db.conversations,
    )..where((t) => t.id.equals(conversation.id))).write(
      ConversationsCompanion(
        title: Value(conversation.title),
        updatedAt: Value(conversation.updatedAt.millisecondsSinceEpoch),
        isPinned: Value(conversation.isPinned),
      ),
    );
  }

  Future<void> delete(String id) async {
    await (_db.delete(
      _db.messages,
    )..where((t) => t.conversationId.equals(id))).go();
    await (_db.delete(_db.conversations)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clearAll() async {
    await _db.delete(_db.messages).go();
    await _db.delete(_db.conversations).go();
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final rows = await (_db.select(
      _db.messages,
    )..where((t) => t.conversationId.equals(conversationId))).get();
    rows.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return rows.map(_toMessage).toList();
  }

  Future<void> addMessage(ChatMessage message) async {
    await _db
        .into(_db.messages)
        .insert(
          MessagesCompanion.insert(
            id: message.id,
            conversationId: message.conversationId,
            role: message.role.name,
            content: message.content,
            createdAt: message.createdAt.millisecondsSinceEpoch,
            status: message.status.name,
          ),
        );
  }

  Future<void> updateMessage(ChatMessage message) async {
    await (_db.update(
      _db.messages,
    )..where((t) => t.id.equals(message.id))).write(
      MessagesCompanion(
        content: Value(message.content),
        status: Value(message.status.name),
      ),
    );
  }

  Conversation _toConversation(ConversationRow row) => Conversation(
    id: row.id,
    title: row.title,
    modelId: row.modelId,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    isPinned: row.isPinned,
  );

  ChatMessage _toMessage(MessageRow row) => ChatMessage(
    id: row.id,
    conversationId: row.conversationId,
    role: MessageRole.values.firstWhere(
      (r) => r.name == row.role,
      orElse: () => MessageRole.user,
    ),
    content: row.content,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    status: MessageStatus.values.firstWhere(
      (s) => s.name == row.status,
      orElse: () => MessageStatus.complete,
    ),
  );
}
