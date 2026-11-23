import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/model_cost_filter.dart';
import '../../../shared/providers/app_providers.dart';

final modelCostFilterProvider =
    StateNotifierProvider<ModelCostFilterNotifier, ModelCostFilter>((ref) {
      return ModelCostFilterNotifier(ref);
    });

class ModelCostFilterNotifier extends StateNotifier<ModelCostFilter> {
  ModelCostFilterNotifier(this.ref) : super(ModelCostFilter.all) {
    _load();
  }

  final Ref ref;
  bool _hasChanged = false;

  Future<void> _load() async {
    final saved = await ref.read(storageServiceProvider).getModelCostFilter();
    if (!_hasChanged) state = ModelCostFilter.fromName(saved);
  }

  Future<void> setFilter(ModelCostFilter filter) async {
    _hasChanged = true;
    state = filter;
    await ref.read(storageServiceProvider).setModelCostFilter(filter.name);
  }
}
