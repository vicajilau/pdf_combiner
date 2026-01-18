import 'package:file_magic_number/file_magic_number.dart';
import 'package:path/path.dart' as p;
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:pdf_combiner/models/merge_input.dart';

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

  /// Determines whether the given file path/blob corresponds to a PDF file.
  static Future<bool> isPDF(String filePath) async {
    try {
      return await FileMagicNumber.detectFileTypeFromPathOrBlob(filePath) ==
          FileMagicNumberType.pdf;
    } catch (e) {
      return false;
    }
  }

  /// Checks if the given file path has a PDF extension.
  static bool hasPDFExtension(String filePath) =>
      p.extension(filePath).toLowerCase() == ".pdf";

  /// Determines whether the given file path/blob corresponds to an image file.
  static Future<bool> isImage(String filePath) async {
    try {
      final fileType =
          await FileMagicNumber.detectFileTypeFromPathOrBlob(filePath);
      return fileType == FileMagicNumberType.png ||
          fileType == FileMagicNumberType.jpg ||
          fileType == FileMagicNumberType.heic;
    } catch (e) {
      return false;
    }
  }

  /// Process a [MergeInput] and return a valid file path (or Blob URL).
  ///
  /// - [MergeInputPath]: Returns the path as-is.
  /// - [MergeInputBytes]: Creates a Blob URL and returns it.
  static Future<String> prepareInput(MergeInput input) async {
    if (input is MergeInputPath) {
      return input.path;
    } else if (input is MergeInputBytes) {
      final JSUint8Array array = input.bytes.toJS;
      final web.Blob blob = web.Blob([array].toJS);
      final String blobUrl = web.URL.createObjectURL(blob);
      return blobUrl;
    } else {
      throw ArgumentError('Unknown MergeInput type');
    }
  }

  /// Cleanup resources for a [MergeInput] after usage.
  ///
  /// - [MergeInputBytes]: Revokes the Blob URL.
  static Future<void> cleanupInput(String path) async {
    if (path.startsWith('blob:')) {
      web.URL.revokeObjectURL(path);
    }
  }
}
