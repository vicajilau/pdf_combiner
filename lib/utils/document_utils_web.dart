import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_magic_number/file_magic_number.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:web/web.dart' as web;

extension on MergeInput {
  Future<Uint8List> readBytes() async {
    switch (this) {
      case MergeInputPath(:final path):
        return Uint8List.fromList(
          await FileMagicNumber.getBytesFromPathOrBlob(path),
        );
      case MergeInputBytes(:final bytes):
        return bytes;
      default:
        throw UnsupportedError('Unsupported MergeInput subtype: $runtimeType');
    }
  }
}

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

  /// Determines whether the given file path/blob corresponds to a PDF file.
  static Future<bool> isPDF(MergeInput input) async {
    final bytes = await input.readBytes();
    return FileMagicNumber.detectFileTypeFromBytes(bytes) ==
        FileMagicNumberType.pdf;
  }

  /// Checks if the given file path has a PDF extension.
  static bool hasPDFExtension(String filePath) =>
      p.extension(filePath).toLowerCase() == ".pdf";

  /// Determines whether the given file path/blob corresponds to an image file.
  static Future<bool> isImage(MergeInput input) async {
    final bytes = await input.readBytes();
    final fileType = FileMagicNumber.detectFileTypeFromBytes(bytes);
    return fileType == FileMagicNumberType.png ||
        fileType == FileMagicNumberType.jpg ||
        fileType == FileMagicNumberType.heic;
  }

  /// Creates a Blob URL from the given bytes with the correct MIME type.
  static String createBlobUrl(Uint8List bytes) {
    final fileType = FileMagicNumber.detectFileTypeFromBytes(bytes);
    String type = '';

    switch (fileType) {
      case FileMagicNumberType.pdf:
        type = 'application/pdf';
        break;
      case FileMagicNumberType.png:
        type = 'image/png';
        break;
      case FileMagicNumberType.jpg:
        type = 'image/jpeg';
        break;
      case FileMagicNumberType.heic:
        type = 'image/heic';
        break;
      default:
        type = 'application/octet-stream';
    }

    final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: type));
    return web.URL.createObjectURL(blob);
  }

  /// Process a [MergeInput] and return a valid file path or blob URL.
  ///
  /// - [MergeInput.path]: Returns the path as-is.
  /// - [MergeInput.bytes] and [MergeInput.url]: Create a blob URL and return it.
  static Future<String> prepareInput(MergeInput input) async {
    switch (input) {
      case MergeInputPath(:final path):
        return path;
      case MergeInputBytes(:final bytes):
        return createBlobUrl(bytes);
      default:
        throw UnsupportedError('Unsupported MergeInput subtype: ${input.runtimeType}');
    }
  }
}
