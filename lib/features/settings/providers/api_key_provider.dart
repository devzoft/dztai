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
    final key = await ref.read(secureKeyServiceProvider).getKey();
    state = AsyncValue.data(key);
  }

  Future<bool> save(String key) async {
    state = const AsyncValue.loading();
    final valid = await ref.read(openRouterServiceProvider).verifyKey(key);
    if (!valid) {
      state = AsyncValue.data(
        await ref.read(secureKeyServiceProvider).getKey(),
      );
      return false;
    }
    await ref.read(secureKeyServiceProvider).saveKey(key);
    state = AsyncValue.data(key);
    return true;
  }

  Future<void> delete() async {
    await ref.read(secureKeyServiceProvider).deleteKey();
    state = const AsyncValue.data(null);
  }
}
