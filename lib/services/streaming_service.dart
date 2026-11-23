import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';

class StreamingService {
  final http.Client _client = http.Client();

  Map<String, String> _headers(String key) => {
    'Authorization': 'Bearer $key',
    'Content-Type': 'application/json',
    'HTTP-Referer': 'https://devzoft.ai',
    'X-Title': 'DevZoft AI',
    'Accept': 'text/event-stream',
  };

  Stream<String> streamChatCompletions({
    required String key,
    required String model,
    required List<Map<String, String>> messages,
    bool stream = true,
  }) async* {
    final req = http.Request(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chatCompletions}'),
    );
    req.headers.addAll(_headers(key));
    req.body = jsonEncode({
      'model': model,
      'messages': messages,
      'stream': stream,
    });

    final res = await _client.send(req);
    if (res.statusCode != 200) {
      final body = await res.stream.bytesToString();
      throw Exception('Chat completions failed: ${res.statusCode} $body');
    }

    await for (final line
        in res.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.startsWith('data:')) {
        final data = line.substring(5).trim();
        if (data == '[DONE]') break;
        if (data.isEmpty) continue;
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = (json['choices'] as List?) ?? [];
          if (choices.isNotEmpty) {
            final delta = choices.first['delta']?['content'];
            if (delta is String && delta.isNotEmpty) yield delta;
            final msg = choices.first['message']?['content'];
            if (msg is String && msg.isNotEmpty && delta == null) yield msg;
          }
        } catch (_) {}
      }
    }
  }

  Stream<String> streamResponses({
    required String key,
    required String model,
    required String input,
  }) async* {
    final req = http.Request(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.responses}'),
    );
    req.headers.addAll(_headers(key));
    req.body = jsonEncode({'model': model, 'input': input, 'stream': true});

    final res = await _client.send(req);
    if (res.statusCode != 200) {
      final body = await res.stream.bytesToString();
      throw Exception('Responses failed: ${res.statusCode} $body');
    }

    await for (final line
        in res.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.startsWith('data:')) {
        final data = line.substring(5).trim();
        if (data == '[DONE]') break;
        if (data.isEmpty) continue;
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          // OpenAI responses streaming events
          final type = json['type']?.toString();
          if (type != null && type.contains('output_text.delta')) {
            final delta = json['delta'];
            if (delta is String) yield delta;
            continue;
          }
          // fallback shapes
          final output = json['output'];
          if (output is List) {
            for (final o in output) {
              final content = o['content'];
              if (content is List) {
                for (final c in content) {
                  final text = c['text'];
                  if (text is String) yield text;
                }
              }
            }
          }
          final choices = (json['choices'] as List?) ?? [];
          if (choices.isNotEmpty) {
            final delta = choices.first['delta']?['content'];
            if (delta is String && delta.isNotEmpty) yield delta;
          }
          final delta = json['delta'];
          if (delta is String && delta.isNotEmpty) yield delta;
        } catch (_) {}
      }
    }
  }
}
