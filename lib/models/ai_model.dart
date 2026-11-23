class AiModel {
  final String id;
  final String name;
  final String? description;
  final String? provider;
  final int? contextLength;
  final double? promptPrice;
  final double? completionPrice;
  final List<String> inputModalities;
  final List<String> outputModalities;
  final List<String> supportedParameters;
  final List<String> endpoints;
  final bool isFree;

  const AiModel({
    required this.id,
    required this.name,
    this.description,
    this.provider,
    this.contextLength,
    this.promptPrice,
    this.completionPrice,
    this.inputModalities = const [],
    this.outputModalities = const [],
    this.supportedParameters = const [],
    this.endpoints = const [],
    this.isFree = false,
  });

  factory AiModel.fromJson(Map<String, dynamic> json) {
    final pricing = (json['pricing'] as Map?)?.cast<String, dynamic>() ?? {};
    final arch = (json['architecture'] as Map?)?.cast<String, dynamic>() ?? {};
    double? parsePrice(dynamic v) {
      if (v == null) return null;
      return double.tryParse(v.toString());
    }

    final input =
        (arch['input_modalities'] as List?)?.cast<String>() ?? <String>[];
    final output =
        (arch['output_modalities'] as List?)?.cast<String>() ?? <String>[];
    final params =
        (json['supported_parameters'] as List?)?.cast<String>() ?? <String>[];
    final endpoints =
        (json['endpoints'] as List?)?.cast<String>() ?? <String>[];
    final prompt = parsePrice(pricing['prompt']);
    final completion = parsePrice(pricing['completion']);
    final id = json['id']?.toString() ?? '';
    final provider = id.contains('/') ? id.split('/').first : null;

    return AiModel(
      id: id,
      name: json['name']?.toString() ?? id,
      description: json['description']?.toString(),
      provider: provider,
      contextLength: (json['context_length'] as num?)?.toInt(),
      promptPrice: prompt,
      completionPrice: completion,
      inputModalities: input,
      outputModalities: output,
      supportedParameters: params,
      endpoints: endpoints,
      isFree: id.endsWith(':free') || (prompt == 0 && completion == 0),
    );
  }

  List<String> get categories {
    final cats = <String>['Chat'];
    if (supportedParameters.any((p) => p.contains('reason'))) {
      cats.add('Reasoning');
    }
    if (inputModalities.contains('image')) {
      cats.add('Vision');
    }
    if (outputModalities.contains('image')) {
      cats.add('Image generation');
    }
    if (inputModalities.contains('audio') ||
        outputModalities.contains('audio')) {
      cats.add('Audio');
    }
    if (inputModalities.contains('video') ||
        outputModalities.contains('video')) {
      cats.add('Video');
    }
    if (supportedParameters.contains('tools')) {
      cats.add('Coding');
    }
    return cats;
  }

  bool supportsResponses() => endpoints.contains('/api/v1/responses');
  bool supportsChatCompletions() =>
      endpoints.contains('/api/v1/chat/completions');

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'provider': provider,
    'context_length': contextLength,
    'prompt': promptPrice,
    'completion': completionPrice,
    'input_modalities': inputModalities,
    'output_modalities': outputModalities,
    'supported_parameters': supportedParameters,
    'endpoints': endpoints,
    'is_free': isFree,
  };
}
