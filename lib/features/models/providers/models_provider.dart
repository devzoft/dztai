import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/app_providers.dart';
import '../../../models/ai_model.dart';
import '../../settings/providers/model_cost_filter_provider.dart';

final modelsProvider = FutureProvider<List<AiModel>>((ref) async {
  final storage = ref.read(storageServiceProvider);
  final cached = await storage.getCachedModels();
  final key = await ref.read(secureKeyServiceProvider).getKey();
  if (key == null) return cached;
  try {
    final fetched = await ref.read(openRouterServiceProvider).fetchModels(key);
    await storage.cacheModels(fetched);
    return fetched;
  } catch (_) {
    return cached;
  }
});

final filteredModelsProvider = Provider<List<AiModel>>((ref) {
  final models = ref.watch(modelsProvider).valueOrNull ?? const <AiModel>[];
  final filter = ref.watch(modelCostFilterProvider);
  return models
      .where((model) => filter.includes(model.isFree))
      .toList(growable: false);
});

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) {
    return FavoritesNotifier(ref);
  },
);

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier(this.ref) : super({}) {
    _load();
  }
  final Ref ref;

  Future<void> _load() async {
    state = await ref.read(storageServiceProvider).getFavorites();
  }

  Future<void> toggle(String id) async {
    final next = Set<String>.from(state);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
    await ref.read(storageServiceProvider).setFavorites(next);
  }
}
