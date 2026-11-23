import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../models/ai_model.dart';
import 'openrouter_headers.dart';

class OpenRouterService {
  final http.Client _client = http.Client();

  Uri _uri(String path) => Uri.parse('${ApiConstants.baseUrl}$path');

  Future<bool> verifyKey(String key) async {
    final res = await _client.get(
      _uri(ApiConstants.models),
      headers: openRouterHeaders(key),
    );
    return res.statusCode == 200;
  }

  Future<List<AiModel>> fetchModels(String key) async {
    final res = await _client.get(
      _uri(ApiConstants.models),
      headers: openRouterHeaders(key),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch models: ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = (body['data'] as List).cast<Map<String, dynamic>>();
    return data.map(AiModel.fromJson).toList();
  }

  Future<Map<String, dynamic>> fetchEndpoints(
    String key,
    String modelId,
  ) async {
    final parts = modelId.split('/');
    if (parts.length < 2) throw Exception('Invalid model id');
    final author = parts.first;
    final slug = parts.sublist(1).join('/');
    // endpoint path uses author/slug; slug may contain slashes? Use canonical? Simpler.
    final res = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/models/$author/$slug/endpoints'),
      headers: openRouterHeaders(key),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed endpoints: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchKeyInfo(String key) async {
    final res = await _client.get(
      _uri(ApiConstants.key),
      headers: openRouterHeaders(key),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed key info: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchCredits(String key) async {
    final res = await _client.get(
      _uri(ApiConstants.credits),
      headers: openRouterHeaders(key),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed credits: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
