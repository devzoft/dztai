import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../models/media_generation_mode.dart';
import '../models/media_model.dart';
import 'openrouter_headers.dart';

class GeneratedMediaOutput {
  const GeneratedMediaOutput({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

class MediaGenerationService {
  final http.Client _client = http.Client();

  Future<List<MediaModel>> fetchModels(
    String key,
    MediaGenerationMode mode,
  ) async {
    final path = switch (mode) {
      MediaGenerationMode.image => ApiConstants.imageModels,
      MediaGenerationMode.audio => ApiConstants.speechModels,
      MediaGenerationMode.video => ApiConstants.videoModels,
      MediaGenerationMode.chat => throw ArgumentError.value(
        mode,
        'mode',
        'Chat models use the general model catalogue.',
      ),
    };
    final response = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}$path'),
      headers: openRouterHeaders(key),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Could not load ${mode.name} models (${response.statusCode}).',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] as List?) ?? const [];
    return data
        .whereType<Map>()
        .map((raw) {
          final json = raw.cast<String, dynamic>();
          return switch (mode) {
            MediaGenerationMode.image => MediaModel.fromImageJson(json),
            MediaGenerationMode.audio => MediaModel.fromSpeechJson(json),
            MediaGenerationMode.video => MediaModel.fromVideoJson(json),
            MediaGenerationMode.chat => throw StateError(
              'Unexpected chat mode',
            ),
          };
        })
        .where((model) => model.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<GeneratedMediaOutput> generateImage({
    required String key,
    required String model,
    required String prompt,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.imageGeneration}'),
      headers: openRouterHeaders(key),
      body: jsonEncode({'model': model, 'prompt': prompt}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwGenerationError('Image', response.statusCode);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List?;
    if (data == null || data.isEmpty || data.first is! Map) {
      throw const FormatException('Image response did not contain an image.');
    }
    final image = (data.first as Map).cast<String, dynamic>();
    final encoded = image['b64_json'];
    if (encoded is! String || encoded.isEmpty) {
      throw const FormatException('Image response did not contain image data.');
    }
    return GeneratedMediaOutput(
      bytes: base64Decode(encoded),
      mimeType: image['media_type']?.toString() ?? 'image/png',
    );
  }

  Future<GeneratedMediaOutput> generateSpeech({
    required String key,
    required String model,
    required String input,
    String? voice,
    String? responseFormat,
  }) async {
    final body = <String, dynamic>{'model': model, 'input': input};
    if (voice != null) body['voice'] = voice;
    if (responseFormat != null) body['response_format'] = responseFormat;
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.speechGeneration}'),
      headers: openRouterHeaders(key, accept: '*/*'),
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwGenerationError('Audio', response.statusCode);
    }
    final mimeType =
        response.headers['content-type']?.split(';').first ?? 'audio/mpeg';
    return GeneratedMediaOutput(bytes: response.bodyBytes, mimeType: mimeType);
  }

  Future<GeneratedMediaOutput> generateVideo({
    required String key,
    required String model,
    required String prompt,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.videoGeneration}'),
      headers: openRouterHeaders(key),
      body: jsonEncode({'model': model, 'prompt': prompt}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwGenerationError('Video', response.statusCode);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final jobId = (body['id'] ?? body['job_id'] ?? body['jobId'])?.toString();
    if (jobId == null || jobId.isEmpty) {
      throw const FormatException('Video response did not include a job ID.');
    }

    final deadline = DateTime.now().add(const Duration(minutes: 10));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 15));
      final statusResponse = await _client.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.videoGeneration}/${Uri.encodeComponent(jobId)}',
        ),
        headers: openRouterHeaders(key),
      );
      if (statusResponse.statusCode != 200) {
        throw Exception(
          'Video status request failed (${statusResponse.statusCode}).',
        );
      }
      final statusBody =
          jsonDecode(statusResponse.body) as Map<String, dynamic>;
      final status = (statusBody['status'] ?? '').toString().toLowerCase();
      if (const {'failed', 'error', 'cancelled', 'expired'}.contains(status)) {
        throw Exception(
          'Video generation did not complete: ${statusBody['error'] ?? status}.',
        );
      }
      if (const {
        'completed',
        'complete',
        'succeeded',
        'success',
      }.contains(status)) {
        final contentResponse = await _client.get(
          Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.videoGeneration}/${Uri.encodeComponent(jobId)}/content',
          ),
          headers: openRouterHeaders(key, accept: 'video/*'),
        );
        if (contentResponse.statusCode < 200 ||
            contentResponse.statusCode >= 300) {
          throw Exception(
            'Could not download generated video (${contentResponse.statusCode}).',
          );
        }
        return GeneratedMediaOutput(
          bytes: contentResponse.bodyBytes,
          mimeType:
              contentResponse.headers['content-type']?.split(';').first ??
              'video/mp4',
        );
      }
    }
    throw TimeoutException('Video generation timed out.');
  }

  Never _throwGenerationError(String kind, int statusCode) {
    if (statusCode == 402) {
      throw Exception(
        '$kind generation requires OpenRouter credits for this model. '
        'Select a free model in Settings or add credits to your OpenRouter account.',
      );
    }
    throw Exception('$kind generation failed ($statusCode).');
  }
}
