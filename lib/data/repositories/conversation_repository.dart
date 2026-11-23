import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../../models/conversation.dart';
import '../../models/chat_message.dart';
import '../../models/generated_media.dart';

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

  Future<Map<String, List<GeneratedMediaAsset>>> getGeneratedMedia(
    String conversationId,
  ) async {
    final query = _db.select(_db.generatedMedia).join([
      innerJoin(
        _db.messages,
        _db.messages.id.equalsExp(_db.generatedMedia.messageId),
      ),
    ])..where(_db.messages.conversationId.equals(conversationId));
    final rows = await query.get();
    final assets = <String, List<GeneratedMediaAsset>>{};
    for (final row in rows) {
      final media = row.readTable(_db.generatedMedia);
      final asset = GeneratedMediaAsset(
        id: media.id,
        messageId: media.messageId,
        kind: GeneratedMediaKind.values.byName(media.kind),
        mimeType: media.mimeType,
        modelId: media.modelId,
        bytes: media.bytes,
        createdAt: DateTime.fromMillisecondsSinceEpoch(media.createdAt),
      );
      assets.putIfAbsent(media.messageId, () => []).add(asset);
    }
    return assets;
  }

  Future<void> addGeneratedMedia(GeneratedMediaAsset media) async {
    await _db
        .into(_db.generatedMedia)
        .insert(
          GeneratedMediaCompanion.insert(
            id: media.id,
            messageId: media.messageId,
            kind: media.kind.name,
            mimeType: media.mimeType,
            modelId: media.modelId,
            bytes: media.bytes,
            createdAt: media.createdAt.millisecondsSinceEpoch,
          ),
        );
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
