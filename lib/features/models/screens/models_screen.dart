import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/models_provider.dart';
import '../../chat/providers/chat_providers.dart';
import '../../settings/providers/model_cost_filter_provider.dart';
import '../../../models/model_cost_filter.dart';

import 'package:go_router/go_router.dart';

class ModelsScreen extends ConsumerStatefulWidget {
  const ModelsScreen({super.key});
  @override
  ConsumerState<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends ConsumerState<ModelsScreen> {
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final asyncModels = ref.watch(modelsProvider);
    final favorites = ref.watch(favoritesProvider);
    final costFilter = ref.watch(modelCostFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(modelsProvider),
          ),
        ],
      ),
      body: asyncModels.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (models) {
          final filtered = models.where((m) {
            if (!costFilter.includes(m.isFree)) {
              return false;
            }
            if (_category != 'All' && !m.categories.contains(_category)) {
              return false;
            }
            if (_query.isNotEmpty) {
              final q = _query.toLowerCase();
              if (!m.name.toLowerCase().contains(q) &&
                  !(m.provider?.toLowerCase().contains(q) ?? false)) {
                return false;
              }
            }
            return true;
          }).toList();

          return Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 430;
                  final search = TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search models or providers',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  );
                  final costFilterMenu = PopupMenuButton<ModelCostFilter>(
                    tooltip: 'Filter models by price',
                    onSelected: (value) => ref
                        .read(modelCostFilterProvider.notifier)
                        .setFilter(value),
                    itemBuilder: (context) => [
                      for (final filter in ModelCostFilter.values)
                        PopupMenuItem(
                          value: filter,
                          child: Text(switch (filter) {
                            ModelCostFilter.all => 'All models',
                            ModelCostFilter.free => 'Free models',
                            ModelCostFilter.paid => 'Paid models',
                          }),
                        ),
                    ],
                    child: Chip(
                      avatar: const Icon(Icons.tune_rounded, size: 17),
                      label: Text(switch (costFilter) {
                        ModelCostFilter.all => 'All',
                        ModelCostFilter.free => 'Free',
                        ModelCostFilter.paid => 'Paid',
                      }),
                    ),
                  );
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: isCompact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              search,
                              Align(
                                alignment: Alignment.centerRight,
                                child: costFilterMenu,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: search),
                              const SizedBox(width: 12),
                              costFilterMenu,
                            ],
                          ),
                  );
                },
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children:
                      [
                        'All',
                        'Chat',
                        'Coding',
                        'Reasoning',
                        'Vision',
                        'Image generation',
                        'Audio',
                        'Video',
                      ].map((c) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c),
                            selected: _category == c,
                            onSelected: (_) => setState(() => _category = c),
                          ),
                        );
                      }).toList(),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final m = filtered[i];
                    final fav = favorites.contains(m.id);
                    final provider = m.provider ?? m.name;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.12),
                            child: Text(
                              provider.isEmpty
                                  ? 'M'
                                  : provider.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(
                            m.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            '${m.provider ?? ''} · ${m.contextLength ?? '?'} context · ${m.isFree ? 'Free' : 'Paid'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: fav ? 'Remove favorite' : 'Add favorite',
                            icon: Icon(
                              fav
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: fav
                                  ? Colors.amber
                                  : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                            ),
                            onPressed: () => ref
                                .read(favoritesProvider.notifier)
                                .toggle(m.id),
                          ),
                          onTap: () => context.push(
                            '/model/${Uri.encodeComponent(m.id)}',
                          ),
                          onLongPress: () {
                            ref.read(selectedModelIdProvider.notifier).state =
                                m.id;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Selected ${m.name}')),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
