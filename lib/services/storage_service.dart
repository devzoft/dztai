import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_model.dart';

class StorageService {
  static const _modelsKey = 'cached_models';
  static const _modelsUpdatedKey = 'models_updated_at';
  static const _themeKey = 'theme_mode';
  static const _defaultModelKey = 'default_model';
  static const _modelCostFilterKey = 'model_cost_filter';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> cacheModels(List<AiModel> models) async {
    final prefs = await _prefs;
    await prefs.setString(
      _modelsKey,
      jsonEncode(models.map((m) => m.toJson()).toList()),
    );
    await prefs.setInt(
      _modelsUpdatedKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<List<AiModel>> getCachedModels() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_modelsKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(AiModel.fromJson).toList();
  }

  Future<DateTime?> modelsUpdatedAt() async {
    final prefs = await _prefs;
    final v = prefs.getInt(_modelsUpdatedKey);
    return v == null ? null : DateTime.fromMillisecondsSinceEpoch(v);
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await _prefs;
    await prefs.setString(_themeKey, mode);
  }

  Future<String?> getThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(_themeKey);
  }

  Future<void> setDefaultModel(String? id) async {
    final prefs = await _prefs;
    if (id == null) {
      await prefs.remove(_defaultModelKey);
    } else {
      await prefs.setString(_defaultModelKey, id);
    }
  }

  Future<String?> getDefaultModel() async {
    final prefs = await _prefs;
    return prefs.getString(_defaultModelKey);
  }

  Future<void> setModelCostFilter(String filter) async {
    final prefs = await _prefs;
    await prefs.setString(_modelCostFilterKey, filter);
  }

  Future<String?> getModelCostFilter() async {
    final prefs = await _prefs;
    return prefs.getString(_modelCostFilterKey);
  }

  Future<Set<String>> getFavorites() async {
    final prefs = await _prefs;
    return (prefs.getStringList('favorites') ?? []).toSet();
  }

  Future<void> setFavorites(Set<String> ids) async {
    final prefs = await _prefs;
    await prefs.setStringList('favorites', ids.toList());
  }
}
