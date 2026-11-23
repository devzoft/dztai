import 'package:flutter_test/flutter_test.dart';

import 'package:dztwai/models/ai_model.dart';
import 'package:dztwai/models/media_model.dart';
import 'package:dztwai/models/model_cost_filter.dart';

void main() {
  group('MediaModel', () {
    test('parses speech voices and supported formats', () {
      final model = MediaModel.fromSpeechJson({
        'id': 'example/voice',
        'output_modalities': [
          {
            'type': 'speech',
            'supported_parameters': {
              'voice': {
                'type': 'enum',
                'values': ['alloy', 'verse'],
              },
              'response_format': {
                'type': 'enum',
                'values': ['mp3', 'wav'],
              },
            },
          },
        ],
      });

      expect(model.id, 'example/voice');
      expect(model.voices, ['alloy', 'verse']);
      expect(model.audioFormats, ['mp3', 'wav']);
    });

    test('parses numeric video capabilities as strings', () {
      final model = MediaModel.fromVideoJson({
        'id': 'example/video',
        'supported_resolutions': ['720p'],
        'supported_aspect_ratios': ['16:9'],
        'supported_durations': [5, 10],
      });

      expect(model.resolutions, ['720p']);
      expect(model.aspectRatios, ['16:9']);
      expect(model.durations, ['5', '10']);
    });
  });

  test('recognizes free model variants when pricing is absent', () {
    final model = AiModel.fromJson({'id': 'example/model:free'});

    expect(model.isFree, isTrue);
  });

  test('pricing filters include the expected models', () {
    expect(ModelCostFilter.all.includes(true), isTrue);
    expect(ModelCostFilter.all.includes(false), isTrue);
    expect(ModelCostFilter.free.includes(true), isTrue);
    expect(ModelCostFilter.free.includes(false), isFalse);
    expect(ModelCostFilter.paid.includes(true), isFalse);
    expect(ModelCostFilter.paid.includes(false), isTrue);
  });

  test('media model free variants are recognized', () {
    expect(
      MediaModel.fromImageJson({'id': 'example/image:free'}).isFree,
      isTrue,
    );
    expect(MediaModel.fromVideoJson({'id': 'example/video'}).isFree, isFalse);
  });
}
