import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/secure_key_service.dart';
import '../../services/storage_service.dart';
import '../../services/openrouter_service.dart';
import '../../services/streaming_service.dart';
import '../../services/media_generation_service.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/conversation_repository.dart';

final secureKeyServiceProvider = Provider<SecureKeyService>(
  (ref) => SecureKeyService(),
);
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);
final openRouterServiceProvider = Provider<OpenRouterService>(
  (ref) => OpenRouterService(),
);
final streamingServiceProvider = Provider<StreamingService>(
  (ref) => StreamingService(),
);
final mediaGenerationServiceProvider = Provider<MediaGenerationService>(
  (ref) => MediaGenerationService(),
);

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
final conversationRepositoryProvider = Provider<ConversationRepository>(
  (ref) => ConversationRepository(ref.read(appDatabaseProvider)),
);
