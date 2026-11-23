import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/providers/chat_providers.dart';
import '../../../shared/providers/app_providers.dart';

import 'package:go_router/go_router.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final asyncConvs = ref.watch(conversationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              await ref.read(conversationRepositoryProvider).clearAll();
              ref.invalidate(conversationsProvider);
            },
          ),
        ],
      ),
      body: asyncConvs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (convs) {
          final filtered = convs
              .where(
                (c) => c.title.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search conversations',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final c = filtered[i];
                    return ListTile(
                      leading: Icon(
                        c.isPinned ? Icons.push_pin : Icons.chat_bubble_outline,
                      ),
                      title: Text(c.title),
                      subtitle: Text(c.modelId),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          final repo = ref.read(conversationRepositoryProvider);
                          if (v == 'open') {
                            context.push('/chat/${Uri.encodeComponent(c.id)}');
                          } else if (v == 'pin') {
                            await repo.update(
                              c.copyWith(
                                isPinned: !c.isPinned,
                                updatedAt: DateTime.now(),
                              ),
                            );
                            ref.invalidate(conversationsProvider);
                          } else if (v == 'rename') {
                            final ctrl = TextEditingController(text: c.title);
                            final title = await showDialog<String>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Rename'),
                                content: TextField(controller: ctrl),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, ctrl.text),
                                    child: const Text('Save'),
                                  ),
                                ],
                              ),
                            );
                            if (title != null && title.trim().isNotEmpty) {
                              await repo.update(
                                c.copyWith(
                                  title: title.trim(),
                                  updatedAt: DateTime.now(),
                                ),
                              );
                              ref.invalidate(conversationsProvider);
                            }
                          } else if (v == 'delete') {
                            await repo.delete(c.id);
                            ref.invalidate(conversationsProvider);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'open', child: Text('Open')),
                          PopupMenuItem(value: 'pin', child: Text('Pin/unpin')),
                          PopupMenuItem(value: 'rename', child: Text('Rename')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                      onTap: () =>
                          context.push('/chat/${Uri.encodeComponent(c.id)}'),
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
