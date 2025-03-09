import 'dart:typed_data';

extension Uint8ListExtension on Uint8List {
  String size() {
    final size = lengthInBytes;

    if (size >= 1e9) {
      return "${(size / 1e9).toStringAsFixed(2)} GB";
    } else if (size >= 1e6) {
      return "${(size / 1e6).toStringAsFixed(2)} MB";
    } else if (size >= 1e3) {
      return "${(size / 1e3).toStringAsFixed(2)} KB";
    }
    return "$size B";
  }
}
