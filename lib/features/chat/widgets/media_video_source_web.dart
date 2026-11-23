import 'dart:js_interop';
import 'dart:typed_data';

import 'package:video_player/video_player.dart';
import 'package:web/web.dart' as web;

import 'media_video_source_type.dart';

Future<MediaVideoSource> createMediaVideoSource(
  Uint8List bytes,
  String mimeType,
) async {
  final blob = web.Blob(
    <web.BlobPart>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final controller = VideoPlayerController.networkUrl(Uri.parse(url));
  return MediaVideoSource(
    controller: controller,
    cleanup: () async {
      await controller.dispose();
      web.URL.revokeObjectURL(url);
    },
  );
}
