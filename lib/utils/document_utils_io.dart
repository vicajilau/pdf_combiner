import 'dart:io';

import 'package:file_magic_number/file_magic_number.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_combiner/pdf_combiner.dart';

/// Utility class for handling document-related checks in a file system environment.
///
/// This implementation is designed for platforms with direct file system access,
/// such as Windows, macOS, Linux, Android, and iOS. The `filePath` parameter
/// should be a valid local file path.
///
/// **Note:** This class is not used on web platforms, which have their own
/// file handling implementation through `DocumentUtilsWeb`.
class DocumentUtils {
  static String _temporalDir = Directory.systemTemp.path;

  /// Removes a list of temporary files from the file system.
  ///
  /// This method iterates through the provided list of file paths and deletes
  /// each file if it exists. For security reasons, it only deletes files that
  /// are located within the designated temporary folder returned by
  /// [getTemporalFolderPath].
  ///
  /// The method is automatically skipped when:
  /// - Running in mock mode ([PdfCombiner.isMock] is `true`)
  /// - Running on web platforms
  ///
  /// **Parameters:**
  /// - [paths]: List of absolute file paths to be removed
  static void removeTemporalFiles(List<String> paths) {
    if (!PdfCombiner.isMock && !kIsWeb) {
      for (final path in paths) {
        // Ensure we only delete files within the designated temporary folder
        if (path.startsWith(getTemporalFolderPath())) {
          final file = File(path);
          if (file.existsSync()) {
            file.deleteSync();
          }
        }
      }
    }
  }

  /// Returns the absolute path to the system's temporary directory.
  ///
  /// By default, this returns the system's temporary directory path
  /// ([Directory.systemTemp.path]). The path can be customized using
  /// [setTemporalFolderPath].
  static String getTemporalFolderPath() => _temporalDir;

  /// Sets a custom temporary folder path for the library to use.
  ///
  /// This method is primarily intended for testing and mocking purposes, allowing
  /// you to control where temporary files are stored during tests. It can also be
  /// used to customize the temporary directory path for the library's operations
  /// on platforms with file system access (Windows, macOS, Linux, Android, iOS).
  ///
  /// **Note:** This setting does not affect web platforms, as they use a different
  /// file handling mechanism.
  ///
  /// **Parameters:**
  /// - [path]: The absolute path to the custom temporary directory
  ///
  /// Example:
  /// ```dart
  /// // In tests
  /// DocumentUtils.setTemporalFolderPath('./example/assets/temp');
  /// ```
  static void setTemporalFolderPath(String path) => _temporalDir = path;

  /// Determines whether the given file path or bytes corresponds to a PDF file.
  ///
  /// This method uses the file's magic number (file signature) to accurately
  /// detect if the file is a PDF, regardless of its extension. This is more
  /// reliable than checking only the file extension.
  ///
  /// **Parameters:**
  /// - [input]: The absolute path to the file or [Uint8List] bytes to check
  ///
  /// **Returns:** `true` if the file is a valid PDF, `false` otherwise
  /// (including when an error occurs during detection)
  static Future<bool> isPDF(dynamic input) async {
    try {
      if (PdfCombiner.isMock && input is String && input.startsWith('blob:')) {
        return true;
      }
      if (input is Uint8List) {
        return FileMagicNumber.detectFileTypeFromBytes(input) ==
            FileMagicNumberType.pdf;
      }
      return await FileMagicNumber.detectFileTypeFromPathOrBlob(input) ==
          FileMagicNumberType.pdf;
    } catch (e) {
      return false;
    }
  }

  /// Checks if the given file path has a PDF extension.
  ///
  /// This is a simple extension check and does not verify if the file is
  /// actually a valid PDF. For accurate PDF detection, use [isPDF] instead.
  ///
  /// **Parameters:**
  /// - [filePath]: The file path to check
  ///
  /// **Returns:** `true` if the file has a `.pdf` extension, `false` otherwise
  static bool hasPDFExtension(String filePath) =>
      p.extension(filePath) == ".pdf";

  /// Determines whether the given file path or bytes corresponds to an image file.
  ///
  /// This method uses the file's magic number (file signature) to detect if
  /// the file is a PNG or JPEG/JPG image, regardless of its extension.
  ///
  /// **Currently supported image formats:**
  /// - PNG
  /// - JPEG/JPG
  ///
  /// **Parameters:**
  /// - [input]: The absolute path to the file or [Uint8List] bytes to check
  ///
  /// **Returns:** `true` if the file is a PNG or JPEG image, `false` otherwise
  /// (including when an error occurs during detection)
  static Future<bool> isImage(dynamic input) async {
    try {
      if (PdfCombiner.isMock && input is String && input.startsWith('blob:')) {
        return true;
      }
      final fileType = input is Uint8List
          ? FileMagicNumber.detectFileTypeFromBytes(input)
          : await FileMagicNumber.detectFileTypeFromPathOrBlob(input);
      return fileType == FileMagicNumberType.png ||
          fileType == FileMagicNumberType.jpg;
    } catch (e) {
      return false;
    }
  }

  /// Checks if the given input is a [File] object.
  static bool isFileSystemFile(dynamic input) => input is File;

  /// Returns the absolute path from a [File] or [String] input.
  static String getFilePath(dynamic input) {
    if (input is File) return input.path;
    if (input is String) return input;
    throw ArgumentError("Expected File or String, got ${input.runtimeType}");
  }

  /// Writes a sequence of [bytes] to a file at the specified [path].
  static Future<void> writeBytesToFile(String path, Uint8List bytes) async {
    await File(path).writeAsBytes(bytes);
  }

  /// Throws [UnsupportedError] on non-web platforms, unless [PdfCombiner.isMock] is true.
  static String createBlobUrl(Uint8List bytes) {
    if (PdfCombiner.isMock) return "blob:mock_url";
    throw UnsupportedError("createBlobUrl is only supported on Web");
  }
}
