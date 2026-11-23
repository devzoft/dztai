import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/app_providers.dart';

final apiKeyProvider = FutureProvider<String?>((ref) async {
  return ref.read(secureKeyServiceProvider).getKey();
});

final apiKeyControllerProvider =
    StateNotifierProvider<ApiKeyController, AsyncValue<String?>>((ref) {
      return ApiKeyController(ref);
    });

class ApiKeyController extends StateNotifier<AsyncValue<String?>> {
  ApiKeyController(this.ref) : super(const AsyncValue.loading()) {
    _load();
  }
  final Ref ref;

  Future<void> _load() async {
    try {
      final key = await ref.read(secureKeyServiceProvider).getKey();
      state = AsyncValue.data(key);
    } on Exception catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> save(String key) async {
    final secureStorage = ref.read(secureKeyServiceProvider);
    final storedKey = await secureStorage.getKey();
    state = const AsyncValue.loading();
    try {
      final valid = await ref.read(openRouterServiceProvider).verifyKey(key);
      if (!valid) {
        state = AsyncValue.data(storedKey);
        return false;
      }
      await secureStorage.saveKey(key);
      state = AsyncValue.data(key);
      return true;
    } on Exception catch (error, stackTrace) {
      state = AsyncValue.data(storedKey);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> delete() async {
    await ref.read(secureKeyServiceProvider).deleteKey();
    state = const AsyncValue.data(null);
  }
}
