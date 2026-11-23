import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/app_providers.dart';
import '../../../models/conversation.dart';
import '../../../models/chat_message.dart';
import '../../../models/ai_model.dart';
import '../../models/providers/models_provider.dart';
import '../../../models/media_generation_mode.dart';
import '../../../models/media_model.dart';

final generationModeProvider = StateProvider<MediaGenerationMode>(
  (ref) => MediaGenerationMode.chat,
);

final selectedMediaModelIdProvider =
    StateProvider.family<String?, MediaGenerationMode>((ref, mode) => null);

final selectedMediaVoiceProvider = StateProvider.family<String?, String>(
  (ref, modelId) => null,
);

final mediaModelsProvider =
    FutureProvider.family<List<MediaModel>, MediaGenerationMode>((
      ref,
      mode,
    ) async {
      final key = await ref.read(secureKeyServiceProvider).getKey();
      if (key == null) return [];
      return ref.read(mediaGenerationServiceProvider).fetchModels(key, mode);
    });

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
  final models = ref.watch(filteredModelsProvider);
  if (models.isEmpty) return null;
  if (id == null) return models.first;
  try {
    return models.firstWhere((m) => m.id == id);
  } catch (_) {
    return models.first;
  }
});
