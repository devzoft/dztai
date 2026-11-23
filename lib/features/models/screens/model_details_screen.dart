import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/ai_model.dart';
import '../providers/models_provider.dart';
import '../../chat/providers/chat_providers.dart';
import '../../../shared/providers/app_providers.dart';

class ModelDetailsScreen extends ConsumerWidget {
  final String modelId;
  const ModelDetailsScreen({super.key, required this.modelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ref.watch(modelsProvider).valueOrNull ?? [];
    AiModel? model;
    for (final m in models) {
      if (m.id == modelId) {
        model = m;
        break;
      }
    }
    if (model == null) {
      return Scaffold(
        appBar: AppBar(title: Text(modelId)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final fav = ref.watch(favoritesProvider).contains(model.id);

    return Scaffold(
      appBar: AppBar(title: Text(model.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(model.name, style: Theme.of(context).textTheme.headlineSmall),
          Text(model.id, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Text(model.description ?? 'No description'),
          const SizedBox(height: 12),
          _row('Provider', model.provider ?? '-'),
          _row('Context length', '${model.contextLength ?? '-'}'),
          _row('Prompt price', '${model.promptPrice ?? 0}'),
          _row('Completion price', '${model.completionPrice ?? 0}'),
          _row('Free', model.isFree ? 'Yes' : 'No'),
          _row('Input modalities', model.inputModalities.join(', ')),
          _row('Output modalities', model.outputModalities.join(', ')),
          _row('Supported params', model.supportedParameters.join(', ')),
          _row('Endpoints', model.endpoints.join(', ')),
          _row('Categories', model.categories.join(', ')),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () {
                  ref.read(selectedModelIdProvider.notifier).state = model!.id;
                  ref.read(storageServiceProvider).setDefaultModel(model.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selected as default')),
                  );
                },
                child: const Text('Use model'),
              ),
              OutlinedButton(
                onPressed: () =>
                    ref.read(favoritesProvider.notifier).toggle(model!.id),
                child: Text(fav ? 'Unfavorite' : 'Favorite'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
