import 'dart:typed_data';
import 'dart:js_interop';
import 'package:file_magic_number/file_magic_number.dart';
import 'package:path/path.dart' as p;
import 'package:web/web.dart' as web;

/// Utility class for handling document-related checks in a web environment.
///
/// This implementation is designed for web platforms where `dart:io` is not available.
/// It uses `package:file_magic_number` for file type detection, which is compatible
/// with both native and web platforms.
class DocumentUtils {
  static String _temporalDir = '';

  /// Removes a list of temporary files (blob URLs) on web.
  static void removeTemporalFiles(List<String> paths) {
    for (final path in paths) {
      if (path.startsWith('blob:')) {
        web.URL.revokeObjectURL(path);
      }
    }
  }

  /// Returns the temporary directory path.
  ///
  /// On web, this returns the value set by [setTemporalFolderPath] or an empty
  /// string by default.
  static String getTemporalFolderPath() => _temporalDir;

  /// Sets a custom temporary folder path.
  ///
  /// This is primarily for maintaining interface parity with the native
  /// implementation.
  static void setTemporalFolderPath(String path) => _temporalDir = path;

  /// Determines whether the given file path/blob/bytes corresponds to a PDF file.
  static Future<bool> isPDF(dynamic input) async {
    try {
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
  static bool hasPDFExtension(String filePath) =>
      p.extension(filePath).toLowerCase() == ".pdf";

  /// Determines whether the given file path/blob/bytes corresponds to an image file.
  static Future<bool> isImage(dynamic input) async {
    try {
      final fileType = input is Uint8List
          ? FileMagicNumber.detectFileTypeFromBytes(input)
          : await FileMagicNumber.detectFileTypeFromPathOrBlob(input);
      return fileType == FileMagicNumberType.png ||
          fileType == FileMagicNumberType.jpg ||
          fileType == FileMagicNumberType.heic;
    } catch (e) {
      return false;
    }
  }

  /// Checks if the given input is a File object.
  /// Always returns `false` on web as `dart:io` Files are not supported.
  static bool isFileSystemFile(dynamic input) => false;

  /// Returns the path string. On web, it only supports [String] inputs.
  static String getFilePath(dynamic input) {
    if (input is String) return input;
    throw ArgumentError("Expected String on Web, got ${input.runtimeType}");
  }

  /// No-op on web.
  static Future<void> writeBytesToFile(String path, Uint8List bytes) async {
    // No-op on web
  }

  /// Creates a Blob URL from the given bytes.
  static String createBlobUrl(Uint8List bytes) {
    final blob = web.Blob([bytes.toJS].toJS);
    return web.URL.createObjectURL(blob);
  }
}
