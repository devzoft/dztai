import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'media_video_source_type.dart';

Future<MediaVideoSource> createMediaVideoSource(
  Uint8List bytes,
  String mimeType,
) async {
  final directory = await getTemporaryDirectory();
  final extension = mimeType.split('/').last.split('+').first;
  final file = File(
    p.join(
      directory.path,
      'generated_${DateTime.now().microsecondsSinceEpoch}.$extension',
    ),
  );
  await file.writeAsBytes(bytes, flush: true);
  final controller = VideoPlayerController.file(file);
  return MediaVideoSource(
    controller: controller,
    cleanup: () async {
      await controller.dispose();
      if (await file.exists()) await file.delete();
    },
  );
}
