import 'dart:io';

/// Utility class for handling document-related checks in a file system environment.
///
/// This implementation is designed for platforms with direct file system access,
/// such as Windows, macOS, and Linux. The `filePath` parameter should be a valid
/// local file path.
class DocumentUtils {
  /// Determines whether the given file path corresponds to a PDF file.
  ///
  /// This method checks if the file path ends with the `.pdf` extension
  /// (case insensitive).
  static bool isPDF(String filePath) => filePath.toLowerCase().endsWith(".pdf");

  /// Determines whether the given file path corresponds to an image file.
  ///
  /// The method checks for common image file extensions (`.jpg`, `.jpeg`, `.png`,
  /// `.gif`, `.bmp`). If the file has no extension, it is assumed to be an image.
  static bool isImage(String filePath) {
    final ext = filePath.toLowerCase();

    return ext.endsWith(".") || // the file has no extension
        ext.endsWith(".jpg") ||
        ext.endsWith(".jpeg") ||
        ext.endsWith(".png") ||
        ext.endsWith(".gif") ||
        ext.endsWith(".bmp");
  }

  /// Checks whether the specified file exists in the file system.
  ///
  /// Uses `File.existsSync()` to determine if the file is present at the given
  /// path. This method is not available on web platforms.
  static bool fileExist(String filePath) => File(filePath).existsSync();
}
