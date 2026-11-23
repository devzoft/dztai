import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/ai_model.dart';
import '../../../models/chat_message.dart';
import '../../../models/conversation.dart';
import '../../../shared/providers/app_providers.dart';
import '../providers/chat_providers.dart';
import '../../models/providers/models_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? conversationId;
  const ChatScreen({super.key, this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  String? _conversationId;
  List<ChatMessage> _messages = [];
  bool _streaming = false;
  StreamSubscription<String>? _sub;
  String _assistantBuffer = '';

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _load();
    _loadDefaultModel();
  }

  Future<void> _loadDefaultModel() async {
    final id = await ref.read(storageServiceProvider).getDefaultModel();
    if (id != null && mounted) {
      ref.read(selectedModelIdProvider.notifier).state = id;
    }
  }

  Future<void> _load() async {
    if (_conversationId == null) return;
    final msgs = await ref
        .read(conversationRepositoryProvider)
        .getMessages(_conversationId!);
    if (mounted) setState(() => _messages = msgs);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _sub?.cancel();
    super.dispose();
  }

  AiModel? get _model => ref.read(selectedModelProvider);

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _streaming) return;
    final model = _model;
    if (model == null) return;
    _input.clear();

    if (_conversationId == null) {
      final conv = Conversation(
        title: text.length > 40 ? '${text.substring(0, 40)}...' : text,
        modelId: model.id,
      );
      await ref.read(conversationRepositoryProvider).create(conv);
      _conversationId = conv.id;
      ref.invalidate(conversationsProvider);
    }

    final userMsg = ChatMessage(
      conversationId: _conversationId!,
      role: MessageRole.user,
      content: text,
    );
    await ref.read(conversationRepositoryProvider).addMessage(userMsg);
    final assistantMsg = ChatMessage(
      conversationId: _conversationId!,
      role: MessageRole.assistant,
      content: '',
      status: MessageStatus.streaming,
    );
    await ref.read(conversationRepositoryProvider).addMessage(assistantMsg);

    setState(() {
      _messages = [..._messages, userMsg, assistantMsg];
      _streaming = true;
      _assistantBuffer = '';
    });
    _scrollToBottom();

    final key = await ref.read(secureKeyServiceProvider).getKey();
    if (key == null) return;

    final history = _messages
        .where((m) => m.id != assistantMsg.id)
        .map((m) => {'role': m.role.name, 'content': m.content})
        .toList();

    final stream = model.supportsResponses()
        ? ref
              .read(streamingServiceProvider)
              .streamResponses(key: key, model: model.id, input: text)
        : ref
              .read(streamingServiceProvider)
              .streamChatCompletions(
                key: key,
                model: model.id,
                messages: history,
              );

    _sub = stream.listen(
      (delta) {
        _assistantBuffer += delta;
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == assistantMsg.id);
          if (idx >= 0) {
            _messages[idx] = _messages[idx].copyWith(
              content: _assistantBuffer,
              status: MessageStatus.streaming,
            );
          }
        });
        _scrollToBottom();
      },
      onDone: () async {
        final finalMsg = ChatMessage(
          id: assistantMsg.id,
          conversationId: _conversationId!,
          role: MessageRole.assistant,
          content: _assistantBuffer,
          createdAt: assistantMsg.createdAt,
          status: MessageStatus.complete,
        );
        await ref.read(conversationRepositoryProvider).updateMessage(finalMsg);
        final conv = (await ref.read(conversationRepositoryProvider).getAll())
            .firstWhere((c) => c.id == _conversationId);
        await ref
            .read(conversationRepositoryProvider)
            .update(conv.copyWith(updatedAt: DateTime.now()));
        ref.invalidate(conversationsProvider);
        if (mounted) setState(() => _streaming = false);
      },
      onError: (e) async {
        final errMsg = ChatMessage(
          id: assistantMsg.id,
          conversationId: _conversationId!,
          role: MessageRole.assistant,
          content: _assistantBuffer.isEmpty ? 'Error: $e' : _assistantBuffer,
          createdAt: assistantMsg.createdAt,
          status: MessageStatus.error,
        );
        await ref.read(conversationRepositoryProvider).updateMessage(errMsg);
        if (mounted) setState(() => _streaming = false);
      },
      cancelOnError: true,
    );
  }

  void _stop() {
    _sub?.cancel();
    setState(() => _streaming = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final models = ref.watch(modelsProvider).valueOrNull ?? [];
    final selectedId = ref.watch(selectedModelIdProvider);
    ref.listen(selectedModelIdProvider, (_, __) {});

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          DropdownButton<String>(
            value: selectedId ?? (models.isNotEmpty ? models.first.id : null),
            items: models
                .map(
                  (m) => DropdownMenuItem(
                    value: m.id,
                    child: Text(m.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (v) =>
                ref.read(selectedModelIdProvider.notifier).state = v,
            underline: const SizedBox(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m.role == MessageRole.user;
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 720),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      m.content.isEmpty && m.status == MessageStatus.streaming
                          ? '...'
                          : m.content,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                if (_streaming)
                  IconButton(onPressed: _stop, icon: const Icon(Icons.stop))
                else
                  IconButton(onPressed: _send, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
