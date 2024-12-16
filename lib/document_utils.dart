class DocumentUtils {
  /// Checks if string is an pdf file.
  static bool isPDF(String filePath) {
    return filePath.toLowerCase().endsWith(".pdf");
  }

  /// Checks if string is an image file.
  static bool isImage(String filePath) {
    final ext = filePath.toLowerCase();

    return ext.endsWith(".jpg") ||
        ext.endsWith(".jpeg") ||
        ext.endsWith(".png") ||
        ext.endsWith(".gif") ||
        ext.endsWith(".bmp");
  }
}
