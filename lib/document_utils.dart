import 'dart:io' as io;
import 'package:flutter/foundation.dart';

class DocumentUtils {
  /// Checks if string is an pdf file.
  static bool isPDF(String filePath) {
    return kIsWeb || filePath.toLowerCase().endsWith(".pdf");
  }

  /// Checks if string is an image file.
  static bool isImage(String filePath) {
    if(kIsWeb) return true;

    final ext = filePath.toLowerCase();

    // If the file has no extension, it is assumed to be a possible image.
    if (!ext.contains(".")) {
      return true;
    }

    return ext.endsWith(".jpg") ||
        ext.endsWith(".jpeg") ||
        ext.endsWith(".png") ||
        ext.endsWith(".gif") ||
        ext.endsWith(".bmp");
  }

  /// Checks if string is an existing file.
  static bool fileExist(String filePath) => kIsWeb || io.File(filePath).existsSync();
}
