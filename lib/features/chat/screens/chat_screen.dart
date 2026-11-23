import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/ai_model.dart';
import '../../../models/chat_message.dart';
import '../../../models/conversation.dart';
import '../../../models/generated_media.dart';
import '../../../models/media_generation_mode.dart';
import '../../../models/media_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../providers/chat_providers.dart';
import '../../models/providers/models_provider.dart';
import '../../settings/providers/model_cost_filter_provider.dart';
import '../widgets/generated_media_view.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? conversationId;
  const ChatScreen({super.key, this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _scroll = ScrollController();
  String? _conversationId;
  List<ChatMessage> _messages = [];
  Map<String, List<GeneratedMediaAsset>> _generatedMedia = {};
  bool _streaming = false;
  bool _isMediaGeneration = false;
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
    final repository = ref.read(conversationRepositoryProvider);
    final msgs = await repository.getMessages(_conversationId!);
    final generatedMedia = await repository.getGeneratedMedia(_conversationId!);
    if (mounted) {
      setState(() {
        _messages = msgs;
        _generatedMedia = generatedMedia;
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    _sub?.cancel();
    super.dispose();
  }

  AiModel? get _model => ref.read(selectedModelProvider);

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _streaming) return;
    final mode = ref.read(generationModeProvider);
    final costFilter = ref.read(modelCostFilterProvider);
    final textModel = mode == MediaGenerationMode.chat ? _model : null;
    final availableMediaModels = mode == MediaGenerationMode.chat
        ? const <MediaModel>[]
        : (ref.read(mediaModelsProvider(mode)).valueOrNull ?? const [])
              .where((model) => costFilter.includes(model.isFree))
              .toList(growable: false);
    final selectedMediaId = mode == MediaGenerationMode.chat
        ? null
        : ref.read(selectedMediaModelIdProvider(mode));
    MediaModel? mediaModel;
    for (final availableModel in availableMediaModels) {
      if (availableModel.id == selectedMediaId) {
        mediaModel = availableModel;
        break;
      }
    }
    mediaModel ??= availableMediaModels.isEmpty
        ? null
        : availableMediaModels.first;
    final modelId = mode == MediaGenerationMode.chat
        ? textModel?.id
        : mediaModel?.id;
    if (modelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No compatible model is available yet.')),
      );
      return;
    }
    _input.clear();

    if (_conversationId == null) {
      final conv = Conversation(
        title: text.length > 40 ? '${text.substring(0, 40)}...' : text,
        modelId: modelId,
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
      _isMediaGeneration = mode != MediaGenerationMode.chat;
      _assistantBuffer = '';
    });
    _scrollToBottom();

    final key = await ref.read(secureKeyServiceProvider).getKey();
    if (key == null) {
      final errorMessage = assistantMsg.copyWith(
        content: 'No OpenRouter API key is configured.',
        status: MessageStatus.error,
      );
      await ref
          .read(conversationRepositoryProvider)
          .updateMessage(errorMessage);
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere(
            (message) => message.id == assistantMsg.id,
          );
          if (index >= 0) _messages[index] = errorMessage;
          _streaming = false;
          _isMediaGeneration = false;
        });
      }
      return;
    }

    if (mode != MediaGenerationMode.chat) {
      await _generateMedia(
        key: key,
        mode: mode,
        model: mediaModel!,
        prompt: text,
        assistantMessage: assistantMsg,
      );
      return;
    }

    final chatModel = textModel;
    if (chatModel == null) {
      throw StateError('A compatible chat model was not selected.');
    }

    final history = _messages
        .where((m) => m.id != assistantMsg.id)
        .map((m) => {'role': m.role.name, 'content': m.content})
        .toList();

    final stream = chatModel.supportsResponses()
        ? ref
              .read(streamingServiceProvider)
              .streamResponses(key: key, model: chatModel.id, input: text)
        : ref
              .read(streamingServiceProvider)
              .streamChatCompletions(
                key: key,
                model: chatModel.id,
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
        if (mounted) {
          setState(() {
            _streaming = false;
            _isMediaGeneration = false;
          });
        }
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
        if (mounted) {
          setState(() {
            _streaming = false;
            _isMediaGeneration = false;
          });
        }
      },
      cancelOnError: true,
    );
  }

  Future<void> _generateMedia({
    required String key,
    required MediaGenerationMode mode,
    required MediaModel model,
    required String prompt,
    required ChatMessage assistantMessage,
  }) async {
    try {
      final service = ref.read(mediaGenerationServiceProvider);
      final selectedVoice = ref.read(selectedMediaVoiceProvider(model.id));
      final voice =
          selectedVoice ?? (model.voices.isEmpty ? null : model.voices.first);
      final responseFormat = model.audioFormats.contains('mp3')
          ? 'mp3'
          : model.audioFormats.isEmpty
          ? null
          : model.audioFormats.first;
      final output = switch (mode) {
        MediaGenerationMode.image => await service.generateImage(
          key: key,
          model: model.id,
          prompt: prompt,
        ),
        MediaGenerationMode.audio => await service.generateSpeech(
          key: key,
          model: model.id,
          input: prompt,
          voice: voice,
          responseFormat: responseFormat,
        ),
        MediaGenerationMode.video => await service.generateVideo(
          key: key,
          model: model.id,
          prompt: prompt,
        ),
        MediaGenerationMode.chat => throw StateError(
          'Chat mode does not generate media.',
        ),
      };
      final media = GeneratedMediaAsset(
        id: const Uuid().v4(),
        messageId: assistantMessage.id,
        kind: switch (mode) {
          MediaGenerationMode.image => GeneratedMediaKind.image,
          MediaGenerationMode.audio => GeneratedMediaKind.audio,
          MediaGenerationMode.video => GeneratedMediaKind.video,
          MediaGenerationMode.chat => throw StateError(
            'Chat mode does not generate media.',
          ),
        },
        mimeType: output.mimeType,
        modelId: model.id,
        bytes: output.bytes,
        createdAt: DateTime.now(),
      );
      final label = switch (mode) {
        MediaGenerationMode.image => 'Image generated',
        MediaGenerationMode.audio => 'Audio generated',
        MediaGenerationMode.video => 'Video generated',
        MediaGenerationMode.chat => '',
      };
      final completeMessage = assistantMessage.copyWith(
        content: label,
        status: MessageStatus.complete,
      );
      final repository = ref.read(conversationRepositoryProvider);
      await repository.addGeneratedMedia(media);
      await repository.updateMessage(completeMessage);
      final conversations = await repository.getAll();
      final conversation = conversations.firstWhere(
        (item) => item.id == _conversationId,
      );
      await repository.update(conversation.copyWith(updatedAt: DateTime.now()));
      ref.invalidate(conversationsProvider);
      if (mounted) {
        setState(() {
          _generatedMedia = {
            ..._generatedMedia,
            assistantMessage.id: [media],
          };
          final index = _messages.indexWhere(
            (message) => message.id == assistantMessage.id,
          );
          if (index >= 0) _messages[index] = completeMessage;
          _streaming = false;
          _isMediaGeneration = false;
        });
        _scrollToBottom();
      }
    } on Exception catch (error) {
      final errorMessage = error.toString().replaceFirst('Exception: ', '');
      final failedMessage = assistantMessage.copyWith(
        content: 'Generation failed: $errorMessage',
        status: MessageStatus.error,
      );
      await ref
          .read(conversationRepositoryProvider)
          .updateMessage(failedMessage);
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere(
            (message) => message.id == assistantMessage.id,
          );
          if (index >= 0) _messages[index] = failedMessage;
          _streaming = false;
          _isMediaGeneration = false;
        });
      }
    }
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
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final models = ref.watch(filteredModelsProvider);
    final costFilter = ref.watch(modelCostFilterProvider);
    final selectedId = ref.watch(selectedModelIdProvider);
    final mode = ref.watch(generationModeProvider);
    final mediaModelsState = mode == MediaGenerationMode.chat
        ? null
        : ref.watch(mediaModelsProvider(mode));
    final mediaModels = (mediaModelsState?.valueOrNull ?? const <MediaModel>[])
        .where((model) => costFilter.includes(model.isFree))
        .toList(growable: false);
    final selectedMediaId = ref.watch(selectedMediaModelIdProvider(mode));
    final selectedMediaCandidates = mediaModels.where(
      (model) => model.id == selectedMediaId,
    );
    final selectedMediaModel = selectedMediaCandidates.isEmpty
        ? null
        : selectedMediaCandidates.first;
    final effectiveMediaModel =
        selectedMediaModel ?? (mediaModels.isEmpty ? null : mediaModels.first);
    final selectedVoiceId = effectiveMediaModel == null
        ? null
        : ref.watch(selectedMediaVoiceProvider(effectiveMediaModel.id));
    final effectiveVoiceId =
        effectiveMediaModel == null || effectiveMediaModel.voices.isEmpty
        ? null
        : effectiveMediaModel.voices.contains(selectedVoiceId)
        ? selectedVoiceId
        : effectiveMediaModel.voices.first;
    final textModelId = models.any((model) => model.id == selectedId)
        ? selectedId
        : models.isEmpty
        ? null
        : models.first.id;
    final selectedDropdownId = mode == MediaGenerationMode.chat
        ? textModelId
        : effectiveMediaModel?.id;
    final modelItems = <DropdownMenuItem<String>>[];
    if (mode == MediaGenerationMode.chat) {
      modelItems.addAll(
        models.map(
          (model) => DropdownMenuItem<String>(
            value: model.id,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isCompact ? 110 : 160),
              child: Text(
                model.name,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ),
      );
    } else {
      modelItems.addAll(
        mediaModels.map(
          (model) => DropdownMenuItem<String>(
            value: model.id,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isCompact ? 110 : 160),
              child: Text(
                model.name,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ),
      );
    }
    final modeLabel = switch (mode) {
      MediaGenerationMode.chat => 'Chat',
      MediaGenerationMode.image => 'Image',
      MediaGenerationMode.audio => 'Audio',
      MediaGenerationMode.video => 'Video',
    };
    final modeIcon = switch (mode) {
      MediaGenerationMode.chat => Icons.chat_bubble_outline_rounded,
      MediaGenerationMode.image => Icons.image_outlined,
      MediaGenerationMode.audio => Icons.graphic_eq_rounded,
      MediaGenerationMode.video => Icons.movie_outlined,
    };
    ref.listen(selectedModelIdProvider, (_, __) {});

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isCompact ? 64 : 76,
        title: Row(
          children: [
            Container(
              width: isCompact ? 34 : 38,
              height: isCompact ? 34 : 38,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(isCompact ? 11 : 13),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 19,
                color: AppColors.accent,
              ),
            ),
            SizedBox(width: isCompact ? 8 : 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Chat'),
                if (!isCompact)
                  Text(
                    'A clear space for your ideas',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            width: isCompact ? 150 : 220,
            constraints: BoxConstraints(maxWidth: isCompact ? 156 : 230),
            margin: EdgeInsets.symmetric(vertical: isCompact ? 10 : 14),
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedDropdownId,
                hint: Text(
                  mediaModelsState?.isLoading == true
                      ? 'Loading...'
                      : 'Choose a model',
                ),
                isDense: true,
                icon: const Icon(Icons.expand_more_rounded, size: 19),
                items: modelItems,
                onChanged: modelItems.isEmpty
                    ? null
                    : (value) {
                        if (mode == MediaGenerationMode.chat) {
                          ref.read(selectedModelIdProvider.notifier).state =
                              value;
                        } else {
                          ref
                                  .read(
                                    selectedMediaModelIdProvider(mode).notifier,
                                  )
                                  .state =
                              value;
                        }
                      },
              ),
            ),
          ),
          SizedBox(width: isCompact ? 6 : 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _EmptyChatState(
                    mode: mode,
                    onSuggestionSelected: (suggestion) {
                      _input.text = suggestion;
                      _input.selection = TextSelection.collapsed(
                        offset: suggestion.length,
                      );
                      _inputFocus.requestFocus();
                    },
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 14 : 24,
                      vertical: isCompact ? 18 : 28,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final isUser = m.role == MessageRole.user;
                      final isStreaming = m.status == MessageStatus.streaming;
                      final content = m.content.isEmpty && isStreaming
                          ? '...'
                          : m.content;
                      final mediaAssets =
                          _generatedMedia[m.id] ??
                          const <GeneratedMediaAsset>[];
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 18),
                            padding: EdgeInsets.all(isCompact ? 14 : 18),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? AppColors.accent.withValues(alpha: 0.1)
                                  : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerLow,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isUser
                                    ? AppColors.accent.withValues(alpha: 0.18)
                                    : Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isUser) ...[
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 16,
                                        color: AppColors.accent,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'DevZoft AI',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      if (isStreaming) ...[
                                        const SizedBox(width: 10),
                                        const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.8,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (isUser)
                                  SelectableText(
                                    content,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge,
                                  )
                                else
                                  SelectionArea(
                                    child: GptMarkdown(
                                      content,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
                                      isStreaming: isStreaming,
                                    ),
                                  ),
                                for (final media in mediaAssets) ...[
                                  const SizedBox(height: 14),
                                  GeneratedMediaView(media: media),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 12 : 20,
                    12,
                    isCompact ? 12 : 20,
                    isCompact ? 8 : 14,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          isCompact ? 6 : 8,
                          6,
                          isCompact ? 6 : 8,
                          6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerLow,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? 0.18
                                    : 0.04,
                              ),
                              blurRadius: 28,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Row(
                                children: [
                                  PopupMenuButton<MediaGenerationMode>(
                                    tooltip: 'Choose generation mode',
                                    onSelected: (value) {
                                      ref
                                              .read(
                                                generationModeProvider.notifier,
                                              )
                                              .state =
                                          value;
                                    },
                                    itemBuilder: (context) => [
                                      for (final item
                                          in MediaGenerationMode.values)
                                        PopupMenuItem(
                                          value: item,
                                          child: Row(
                                            children: [
                                              Icon(switch (item) {
                                                MediaGenerationMode.chat =>
                                                  Icons
                                                      .chat_bubble_outline_rounded,
                                                MediaGenerationMode.image =>
                                                  Icons.image_outlined,
                                                MediaGenerationMode.audio =>
                                                  Icons.graphic_eq_rounded,
                                                MediaGenerationMode.video =>
                                                  Icons.movie_outlined,
                                              }, size: 18),
                                              const SizedBox(width: 10),
                                              Text(switch (item) {
                                                MediaGenerationMode.chat =>
                                                  'Chat',
                                                MediaGenerationMode.image =>
                                                  'Generate image',
                                                MediaGenerationMode.audio =>
                                                  'Generate audio',
                                                MediaGenerationMode.video =>
                                                  'Generate video',
                                              }),
                                            ],
                                          ),
                                        ),
                                    ],
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            modeIcon,
                                            size: 18,
                                            color: AppColors.accent,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            modeLabel,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge,
                                          ),
                                          const Icon(
                                            Icons.expand_more_rounded,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (mode == MediaGenerationMode.audio &&
                                      effectiveMediaModel != null &&
                                      effectiveMediaModel.voices.isNotEmpty)
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: effectiveVoiceId,
                                        isDense: true,
                                        icon: const Icon(
                                          Icons.expand_more_rounded,
                                          size: 18,
                                        ),
                                        items: effectiveMediaModel.voices
                                            .map(
                                              (voice) =>
                                                  DropdownMenuItem<String>(
                                                    value: voice,
                                                    child: ConstrainedBox(
                                                      constraints:
                                                          const BoxConstraints(
                                                            maxWidth: 110,
                                                          ),
                                                      child: Text(
                                                        voice,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                            )
                                            .toList(),
                                        onChanged: _streaming
                                            ? null
                                            : (voice) {
                                                if (voice != null) {
                                                  ref
                                                          .read(
                                                            selectedMediaVoiceProvider(
                                                              effectiveMediaModel
                                                                  .id,
                                                            ).notifier,
                                                          )
                                                          .state =
                                                      voice;
                                                }
                                              },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _input,
                                    focusNode: _inputFocus,
                                    minLines: 1,
                                    maxLines: isCompact ? 4 : 6,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    decoration: InputDecoration(
                                      hintText: switch (mode) {
                                        MediaGenerationMode.chat =>
                                          'Ask anything...',
                                        MediaGenerationMode.image =>
                                          'Describe an image...',
                                        MediaGenerationMode.audio =>
                                          'Write the text to speak...',
                                        MediaGenerationMode.video =>
                                          'Describe a video...',
                                      },
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      filled: false,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                    ),
                                    onSubmitted: (_) => _send(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_streaming && !_isMediaGeneration)
                                  IconButton.filled(
                                    tooltip: 'Stop generating',
                                    onPressed: _stop,
                                    icon: const Icon(Icons.stop_rounded),
                                  )
                                else if (_streaming)
                                  const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                else
                                  IconButton.filled(
                                    tooltip: 'Generate',
                                    onPressed: _send,
                                    icon: const Icon(
                                      Icons.arrow_upward_rounded,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(height: 10),
                        Text(
                          'AI can make mistakes. Check important information.',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({
    required this.mode,
    required this.onSuggestionSelected,
  });

  final MediaGenerationMode mode;
  final ValueChanged<String> onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (heading, description, suggestions) = switch (mode) {
      MediaGenerationMode.chat => (
        'What can we work on?',
        'Choose a model, bring a question, and make something useful.',
        const [
          ('Create', 'Help me draft a clear project plan'),
          ('Understand', 'Explain a complex idea in simple terms'),
          ('Solve', 'Help me think through a tricky problem'),
        ],
      ),
      MediaGenerationMode.image => (
        'Imagine it. Create it.',
        'Describe the image you want and choose an image generation model.',
        const [
          ('Illustration', 'A cozy reading nook on a rainy afternoon'),
          ('Product', 'A minimal product photo with soft studio lighting'),
          ('Landscape', 'A cinematic view of a quiet mountain lake'),
        ],
      ),
      MediaGenerationMode.audio => (
        'Give your words a voice.',
        'Write the text and choose a voice to generate spoken audio.',
        const [
          ('Welcome', 'Welcome to the team. We are glad you are here.'),
          ('Narration', 'The sun rose slowly over the quiet city.'),
          ('Reminder', 'Take a moment to pause and enjoy the day.'),
        ],
      ),
      MediaGenerationMode.video => (
        'Bring a scene to life.',
        'Describe a scene to generate a video with a compatible model.',
        const [
          ('Nature', 'A slow cinematic sunrise over ocean waves'),
          ('Travel', 'A train passing through a green mountain valley'),
          ('Abstract', 'Soft flowing emerald light in a dark space'),
        ],
      ),
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.accent,
                  size: 30,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                heading,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final (label, prompt) in suggestions)
                    ActionChip(
                      avatar: const Icon(Icons.arrow_outward_rounded, size: 15),
                      label: Text('$label · $prompt'),
                      onPressed: () => onSuggestionSelected(prompt),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
