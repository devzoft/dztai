import 'dart:typed_data';

enum GeneratedMediaKind { image, audio, video }

class GeneratedMediaAsset {
  const GeneratedMediaAsset({
    required this.id,
    required this.messageId,
    required this.kind,
    required this.mimeType,
    required this.modelId,
    required this.bytes,
    required this.createdAt,
  });

  final String id;
  final String messageId;
  final GeneratedMediaKind kind;
  final String mimeType;
  final String modelId;
  final Uint8List bytes;
  final DateTime createdAt;
}
