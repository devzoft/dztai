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
          _row(context, 'Provider', model.provider ?? '-'),
          _row(context, 'Context length', '${model.contextLength ?? '-'}'),
          _row(context, 'Prompt price', '${model.promptPrice ?? 0}'),
          _row(context, 'Completion price', '${model.completionPrice ?? 0}'),
          _row(context, 'Free', model.isFree ? 'Yes' : 'No'),
          _row(context, 'Input modalities', model.inputModalities.join(', ')),
          _row(context, 'Output modalities', model.outputModalities.join(', ')),
          _row(
            context,
            'Supported params',
            model.supportedParameters.join(', '),
          ),
          _row(context, 'Endpoints', model.endpoints.join(', ')),
          _row(context, 'Categories', model.categories.join(', ')),
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

  Widget _row(BuildContext context, String label, String value) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 440;
        final labelStyle = Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
        final valueStyle = Theme.of(context).textTheme.bodyMedium;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: labelStyle),
                    const SizedBox(height: 4),
                    Text(value, style: valueStyle),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 180, child: Text(label, style: labelStyle)),
                    Expanded(child: Text(value, style: valueStyle)),
                  ],
                ),
        );
      },
    );
  }
}
