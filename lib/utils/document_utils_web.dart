import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_magic_number/file_magic_number.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/utils/string_extenxion.dart';
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

  /// Determines whether the given file path/blob corresponds to a PDF file.
  static Future<bool> isPDF(MergeInput input) async {
    switch (input.type) {
      case MergeInputType.path:
        return await FileMagicNumber.detectFileTypeFromPathOrBlob(
                input.path!) ==
            FileMagicNumberType.pdf;
      case MergeInputType.bytes:
        return FileMagicNumber.detectFileTypeFromBytes(input.bytes!) ==
            FileMagicNumberType.pdf;
      case MergeInputType.url:
        return input.url.stringToMagicType == FileMagicNumberType.pdf;
    }
  }

  /// Checks if the given file path has a PDF extension.
  static bool hasPDFExtension(String filePath) =>
      p.extension(filePath).toLowerCase() == ".pdf";

  /// Determines whether the given file path/blob corresponds to an image file.
  static Future<bool> isImage(MergeInput input) async {
    late FileMagicNumberType fileType;
    switch (input.type) {
      case MergeInputType.path:
        fileType =
            await FileMagicNumber.detectFileTypeFromPathOrBlob(input.path!);
        break;
      case MergeInputType.bytes:
        fileType = FileMagicNumber.detectFileTypeFromBytes(input.bytes!);
        break;
      case MergeInputType.url:
        fileType = input.url.stringToMagicType;
        break;
    }
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
  /// - [MergeInput.bytes]: Creates a blob URL and returns it.
  /// - [MergeInput.url]: Returns the URL as-is.
  static Future<String> prepareInput(MergeInput input) async {
    switch (input.type) {
      case MergeInputType.path:
        return input.path!;
      case MergeInputType.bytes:
        return createBlobUrl(input.bytes!);
      case MergeInputType.url:
        return input.url!;
    }
  }
 
  static Future<List<MergeInput>> conversionUrlInputsToPaths(
      List<MergeInput> inputs) async { 
    return inputs;
  }
}
