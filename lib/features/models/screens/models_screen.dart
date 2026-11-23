import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/models_provider.dart';
import '../../chat/providers/chat_providers.dart';

import 'package:go_router/go_router.dart';

class ModelsScreen extends ConsumerStatefulWidget {
  const ModelsScreen({super.key});
  @override
  ConsumerState<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends ConsumerState<ModelsScreen> {
  String _query = '';
  String _category = 'All';
  bool _freeOnly = false;

  @override
  Widget build(BuildContext context) {
    final asyncModels = ref.watch(modelsProvider);
    final favorites = ref.watch(favoritesProvider);

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
            if (_freeOnly && !m.isFree) {
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
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search models/providers',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Free'),
                      selected: _freeOnly,
                      onSelected: (v) => setState(() => _freeOnly = v),
                    ),
                  ],
                ),
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
                    return ListTile(
                      title: Text(m.name),
                      subtitle: Text(
                        '${m.provider ?? ''} • ctx ${m.contextLength ?? '?'} • ${m.isFree ? 'Free' : 'Paid'}',
                      ),
                      trailing: IconButton(
                        icon: Icon(fav ? Icons.star : Icons.star_border),
                        onPressed: () =>
                            ref.read(favoritesProvider.notifier).toggle(m.id),
                      ),
                      onTap: () =>
                          context.push('/model/${Uri.encodeComponent(m.id)}'),
                      onLongPress: () {
                        ref.read(selectedModelIdProvider.notifier).state = m.id;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Selected ${m.name}')),
                        );
                      },
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
