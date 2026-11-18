import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

Future<(int, int)?> imageDimensions(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      final w = frame.image.width;
      final h = frame.image.height;
      frame.image.dispose();
      return (w, h);
    } finally {
      codec.dispose();
    }
  } catch (_) {
    return null;
  }
}

Future<Uint8List?> makeAvatarPng(Uint8List bytes, {int maxSize = 192}) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      final src = frame.image;
      final scale = math.min(
        1.0,
        maxSize / math.max(src.width, src.height).toDouble(),
      );
      final w = math.max(1, (src.width * scale).round());
      final h = math.max(1, (src.height * scale).round());
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = ui.Paint()..filterQuality = ui.FilterQuality.high;
      canvas.drawImageRect(
        src,
        ui.Rect.fromLTWH(0, 0, src.width.toDouble(), src.height.toDouble()),
        ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        paint,
      );
      final picture = recorder.endRecording();
      final out = await picture.toImage(w, h);
      final data = await out.toByteData(format: ui.ImageByteFormat.png);
      picture.dispose();
      out.dispose();
      src.dispose();
      return data?.buffer.asUint8List();
    } finally {
      codec.dispose();
    }
  } catch (_) {
    return null;
  }
}
