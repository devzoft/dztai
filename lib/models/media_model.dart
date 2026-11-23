class MediaModel {
  const MediaModel({
    required this.id,
    required this.name,
    this.description,
    this.voices = const [],
    this.audioFormats = const [],
    this.resolutions = const [],
    this.aspectRatios = const [],
    this.durations = const [],
  });

  final String id;
  final String name;
  final String? description;
  final List<String> voices;
  final List<String> audioFormats;
  final List<String> resolutions;
  final List<String> aspectRatios;
  final List<String> durations;

  bool get isFree => id.endsWith(':free');

  factory MediaModel.fromImageJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['id']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  factory MediaModel.fromSpeechJson(Map<String, dynamic> json) {
    final outputs = (json['output_modalities'] as List?) ?? const [];
    final speech = outputs
        .whereType<Map>()
        .map((output) => output.cast<String, dynamic>())
        .firstWhere(
          (output) => output['type'] == 'speech',
          orElse: () => const {},
        );
    final parameters =
        speech['supported_parameters'] as Map<String, dynamic>? ?? const {};
    return MediaModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['id']?.toString() ?? '',
      description: json['description']?.toString(),
      voices: _enumValues(parameters['voice']),
      audioFormats: _enumValues(parameters['response_format']),
    );
  }

  factory MediaModel.fromVideoJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['id']?.toString() ?? '',
      description: json['description']?.toString(),
      resolutions: _strings(json['supported_resolutions']),
      aspectRatios: _strings(json['supported_aspect_ratios']),
      durations: _strings(json['supported_durations']),
    );
  }

  static List<String> _enumValues(dynamic parameter) {
    if (parameter is! Map) return const [];
    return _strings(parameter['values']);
  }

  static List<String> _strings(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList(growable: false);
  }
}
