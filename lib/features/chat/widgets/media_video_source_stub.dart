import 'dart:typed_data';

import 'media_video_source_type.dart';

Future<MediaVideoSource> createMediaVideoSource(
  Uint8List bytes,
  String mimeType,
) =>
    throw UnsupportedError('Video playback is not supported on this platform.');
