/// A utility class providing methods to handle documents and files.
///
/// This class is used to check if a file is a PDF, an image, or if it exists.
/// It provides static methods that can be invoked without creating an instance.
/// Depending on the runtime environment (IO or Web), different implementations
/// are provided for checking files and handling document-specific tasks.
///
/// The class is designed to be used with platform-specific imports to handle
/// different file operations on web and native platforms.
///
/// Example usage:
/// ```dart
/// bool isPdf = DocumentUtils.isPDF('path/to/file.pdf');
/// bool fileExists = DocumentUtils.fileExist('path/to/file.pdf');
/// ```
class DocumentUtils {
  /// Checks if the given file is a PDF.
  ///
  /// This method takes a file path (`filePath`) as input and checks whether
  /// the file is a PDF. The current implementation always returns `false`,
  /// but platform-specific implementations may override this method.
  ///
  /// [filePath] The path of the file to be checked.
  ///
  /// Returns:
  /// A boolean indicating whether the file is a PDF (default: `false`).
  static bool isPDF(String filePath) => false;

  /// Checks if the given file is an image.
  ///
  /// This method takes a file path (`filePath`) as input and checks whether
  /// the file is an image. The current implementation always returns `false`,
  /// but platform-specific implementations may override this method.
  ///
  /// [filePath] The path of the file to be checked.
  ///
  /// Returns:
  /// A boolean indicating whether the file is an image (default: `false`).
  static bool isImage(String filePath) => false;

  /// Checks if the given file exists.
  ///
  /// This method takes a file path (`filePath`) as input and checks whether
  /// the file exists. The current implementation always returns `false`,
  /// but platform-specific implementations may override this method.
  ///
  /// [filePath] The path of the file to be checked.
  ///
  /// Returns:
  /// A boolean indicating whether the file exists (default: `false`).
  static bool fileExist(String filePath) => false;
}
