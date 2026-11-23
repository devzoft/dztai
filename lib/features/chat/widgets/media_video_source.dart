import 'dart:typed_data';

import 'media_video_source_type.dart';
import 'media_video_source_stub.dart'
    if (dart.library.io) 'media_video_source_io.dart'
    if (dart.library.html) 'media_video_source_web.dart'
    as implementation;

Future<MediaVideoSource> createMediaVideoSource(
  Uint8List bytes,
  String mimeType,
) => implementation.createMediaVideoSource(bytes, mimeType);
