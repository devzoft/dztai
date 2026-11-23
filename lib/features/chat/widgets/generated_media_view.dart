import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

import '../../../models/generated_media.dart';
import 'media_video_source.dart';
import 'media_video_source_type.dart';

class GeneratedMediaView extends StatelessWidget {
  const GeneratedMediaView({super.key, required this.media});

  final GeneratedMediaAsset media;

  @override
  Widget build(BuildContext context) {
    final output = switch (media.kind) {
      GeneratedMediaKind.image => _ImageOutput(media: media),
      GeneratedMediaKind.audio => _AudioOutput(media: media),
      GeneratedMediaKind.video => _VideoOutput(media: media),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        output,
        Align(
          alignment: Alignment.centerRight,
          child: _SaveGeneratedMediaButton(media: media),
        ),
      ],
    );
  }
}

class _SaveGeneratedMediaButton extends StatefulWidget {
  const _SaveGeneratedMediaButton({required this.media});

  final GeneratedMediaAsset media;

  @override
  State<_SaveGeneratedMediaButton> createState() =>
      _SaveGeneratedMediaButtonState();
}

class _SaveGeneratedMediaButtonState extends State<_SaveGeneratedMediaButton> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final media = widget.media;
      final path = await FileSaver.instance.saveAs(
        name:
            'devzoft-ai-${media.kind.name}-${media.createdAt.millisecondsSinceEpoch}',
        bytes: media.bytes,
        fileExtension: _fileExtension(media.mimeType),
        mimeType: MimeType.custom,
        customMimeType: media.mimeType.split(';').first,
        dialogTitle: 'Save generated ${media.kind.name}',
      );
      if (mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved ${media.kind.name} to $path')),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save file: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _fileExtension(String mimeType) {
    final normalized = mimeType.split(';').first.trim().toLowerCase();
    return switch (normalized) {
      'image/jpeg' => 'jpg',
      'image/svg+xml' => 'svg',
      'audio/mpeg' => 'mp3',
      'audio/wav' || 'audio/x-wav' => 'wav',
      'audio/mp4' => 'm4a',
      _ => normalized.split('/').last.split('+').first,
    };
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _saving ? null : _save,
      icon: _saving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download_rounded, size: 18),
      label: Text(_saving ? 'Saving...' : 'Save'),
    );
  }
}

class _ImageOutput extends StatelessWidget {
  const _ImageOutput({required this.media});

  final GeneratedMediaAsset media;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: media.mimeType == 'image/svg+xml'
            ? SvgPicture.memory(media.bytes, fit: BoxFit.contain)
            : Image.memory(media.bytes, fit: BoxFit.contain),
      ),
    );
  }
}

class _AudioOutput extends StatefulWidget {
  const _AudioOutput({required this.media});

  final GeneratedMediaAsset media;

  @override
  State<_AudioOutput> createState() => _AudioOutputState();
}

class _AudioOutputState extends State<_AudioOutput> {
  late final AudioPlayer _player;
  late final StreamSubscription<PlayerState> _stateSubscription;
  bool _isPlaying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    unawaited(_stateSubscription.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play(
          BytesSource(widget.media.bytes, mimeType: widget.media.mimeType),
        );
      }
      if (mounted) setState(() => _error = null);
    } on Exception {
      if (mounted) {
        setState(() => _error = 'Audio playback is not available.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: _isPlaying ? 'Pause audio' : 'Play audio',
            onPressed: _togglePlayback,
            icon: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error ?? 'Generated audio · ${widget.media.mimeType}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoOutput extends StatefulWidget {
  const _VideoOutput({required this.media});

  final GeneratedMediaAsset media;

  @override
  State<_VideoOutput> createState() => _VideoOutputState();
}

class _VideoOutputState extends State<_VideoOutput> {
  MediaVideoSource? _source;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    MediaVideoSource? source;
    try {
      source = await createMediaVideoSource(
        widget.media.bytes,
        widget.media.mimeType,
      );
      await source.controller.initialize();
      if (!mounted) {
        await source.dispose();
        return;
      }
      setState(() => _source = source);
    } on Exception {
      if (source != null) await source.dispose();
      if (mounted) {
        setState(() => _error = 'Video playback is not available.');
      }
    }
  }

  @override
  void dispose() {
    final source = _source;
    if (source != null) unawaited(source.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = _source;
    if (source == null) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: _error == null
            ? const CircularProgressIndicator()
            : Text(_error!),
      );
    }
    final controller = source.controller;
    final value = controller.value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            IconButton.filledTonal(
              tooltip: value.isPlaying ? 'Pause video' : 'Play video',
              onPressed: () async {
                if (value.isPlaying) {
                  await controller.pause();
                } else {
                  await controller.play();
                }
                if (mounted) setState(() {});
              },
              icon: Icon(
                value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
