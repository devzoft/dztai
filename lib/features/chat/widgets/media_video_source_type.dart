import 'package:video_player/video_player.dart';

class MediaVideoSource {
  const MediaVideoSource({required this.controller, required this.cleanup});

  final VideoPlayerController controller;
  final Future<void> Function() cleanup;

  Future<void> dispose() => cleanup();
}
