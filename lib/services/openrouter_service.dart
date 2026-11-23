import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../models/ai_model.dart';

class OpenRouterService {
  final http.Client _client = http.Client();

  Uri _uri(String path) => Uri.parse('${ApiConstants.baseUrl}$path');

  Map<String, String> _headers(String key) => {
    'Authorization': 'Bearer $key',
    'Content-Type': 'application/json',
    'HTTP-Referer': 'https://devzoft.ai',
    'X-Title': 'DevZoft AI',
  };

  Future<bool> verifyKey(String key) async {
    final res = await _client.get(
      _uri(ApiConstants.models),
      headers: _headers(key),
    );
    return res.statusCode == 200;
  }

  Future<List<AiModel>> fetchModels(String key) async {
    final res = await _client.get(
      _uri(ApiConstants.models),
      headers: _headers(key),
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
      headers: _headers(key),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed endpoints: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchKeyInfo(String key) async {
    final res = await _client.get(
      _uri(ApiConstants.key),
      headers: _headers(key),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed key info: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchCredits(String key) async {
    final res = await _client.get(
      _uri(ApiConstants.credits),
      headers: _headers(key),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed credits: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
