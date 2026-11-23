import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/api_key_provider.dart';
import '../providers/model_cost_filter_provider.dart';
import '../providers/theme_provider.dart';
import '../../chat/providers/chat_providers.dart';
import '../../models/providers/models_provider.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../models/model_cost_filter.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _keyCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyState = ref.watch(apiKeyControllerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final models = ref.watch(filteredModelsProvider);
    final modelCostFilter = ref.watch(modelCostFilterProvider);
    final selectedId = ref.watch(selectedModelIdProvider);
    final visibleSelectedId = selectedId == null
        ? null
        : models.any((model) => model.id == selectedId)
        ? selectedId
        : models.isEmpty
        ? null
        : models.first.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('API Key', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _keyCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'OpenRouter API Key',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton(
                onPressed: keyState.isLoading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await ref
                            .read(apiKeyControllerProvider.notifier)
                            .save(_keyCtrl.text.trim());
                        if (!ok && mounted) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Invalid key')),
                          );
                        } else if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Saved')),
                          );
                          ref.invalidate(modelsProvider);
                        }
                      },
                child: const Text('Save / Verify'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(apiKeyControllerProvider.notifier).delete();
                  _keyCtrl.clear();
                },
                child: const Text('Delete'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Current: ${keyState.valueOrNull == null ? 'none' : 'configured'}',
          ),
          const Divider(height: 32),
          Text('Theme', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {themeMode},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).setMode(s.first),
          ),
          const Divider(height: 32),
          Text(
            'Model pricing filter',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Choose which models are available for chat, media generation, and discovery.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          SegmentedButton<ModelCostFilter>(
            segments: const [
              ButtonSegment(value: ModelCostFilter.all, label: Text('All')),
              ButtonSegment(value: ModelCostFilter.free, label: Text('Free')),
              ButtonSegment(value: ModelCostFilter.paid, label: Text('Paid')),
            ],
            selected: {modelCostFilter},
            onSelectionChanged: (selection) => ref
                .read(modelCostFilterProvider.notifier)
                .setFilter(selection.first),
          ),
          const Divider(height: 32),
          Text('Default model', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: visibleSelectedId,
            hint: const Text('Select default model'),
            items: models
                .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                .toList(),
            onChanged: (v) {
              ref.read(selectedModelIdProvider.notifier).state = v;
              ref.read(storageServiceProvider).setDefaultModel(v);
            },
          ),
          const Divider(height: 32),
          Text('Data', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await ref.read(conversationRepositoryProvider).clearAll();
              ref.invalidate(conversationsProvider);
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('History cleared')),
                );
              }
            },
            child: const Text('Clear all history'),
          ),
          const Divider(height: 32),
          Text('About', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('DevZoft AI v1.0.0'),
          const Text('Developer: Amal K P DevZoft'),
        ],
      ),
    );
  }
}
