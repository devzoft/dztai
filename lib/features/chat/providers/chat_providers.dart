import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/app_providers.dart';
import '../../../models/conversation.dart';
import '../../../models/chat_message.dart';
import '../../../models/ai_model.dart';
import '../../models/providers/models_provider.dart';

final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  return ref.read(conversationRepositoryProvider).getAll();
});

final currentConversationIdProvider = StateProvider<String?>((ref) => null);

final messagesProvider = FutureProvider.family<List<ChatMessage>, String>((
  ref,
  conversationId,
) async {
  return ref.read(conversationRepositoryProvider).getMessages(conversationId);
});

final selectedModelIdProvider = StateProvider<String?>((ref) => null);

final selectedModelProvider = Provider<AiModel?>((ref) {
  final id = ref.watch(selectedModelIdProvider);
  final models = ref.watch(modelsProvider).valueOrNull ?? [];
  if (models.isEmpty) return null;
  if (id == null) return models.first;
  try {
    return models.firstWhere((m) => m.id == id);
  } catch (_) {
    return models.first;
  }
});
