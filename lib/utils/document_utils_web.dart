import 'dart:typed_data';
import 'package:file_magic_number/file_magic_number.dart';
import 'package:path/path.dart' as p;

/// Utility class for handling document-related checks in a web environment.
///
/// This implementation is designed for web platforms where `dart:io` is not available.
/// It uses `package:file_magic_number` for file type detection, which is compatible
/// with both native and web platforms.
class DocumentUtils {
  static String _temporalDir = '';

  /// Removes a list of temporary files.
  ///
  /// **Note:** This is a no-op on web platforms as they do not have direct
  /// file system access for deletion.
  static void removeTemporalFiles(List<String> paths) {
    // No-op on web
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
        return await FileMagicNumber.detectFileTypeFromBytes(input) ==
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
          ? await FileMagicNumber.detectFileTypeFromBytes(input)
          : await FileMagicNumber.detectFileTypeFromPathOrBlob(input);
      return fileType == FileMagicNumberType.png ||
          fileType == FileMagicNumberType.jpg;
    } catch (e) {
      return false;
    }
  }
}
