/// Utility class for handling document-related checks in a web environment.
///
/// Since the web does not have direct file system access, `filePath` will
/// typically be a `Blob` or a URL rather than a traditional file path.
/// Some methods always return `true` to reflect the limitations of web-based
/// file handling.
class DocumentUtils {
  /// Determines whether the given file path corresponds to a PDF file.
  ///
  /// On the web, file paths are often URLs or Blobs, so type validation is
  /// limited. This method always returns `true`.
  static bool isPDF(String filePath) => true;

  /// Determines whether the given file path corresponds to an image file.
  ///
  /// Since the web does not provide traditional file system access,
  /// this method always returns `true`, assuming any file could be an image.
  static bool isImage(String filePath) => true;

  /// Checks whether the specified file exists.
  ///
  /// On the web, direct file system checks are not possible. This method
  /// always returns `true` to avoid breaking file existence checks in
  /// cross-platform code.
  static bool fileExist(String filePath) => true;
}
