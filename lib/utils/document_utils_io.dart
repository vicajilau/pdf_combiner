import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_magic_number/file_magic_number.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';

extension on FileMagicNumberType {
  String extension() {
    switch (this) {
      case FileMagicNumberType.pdf:
        return '.pdf';
      case FileMagicNumberType.png:
        return '.png';
      case FileMagicNumberType.jpg:
        return '.jpg';
      case FileMagicNumberType.heic:
        return '.heic';
      default:
        return '.bin';
    }
  }
}

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

  // URL download helper removed: URL-backed inputs are no longer supported.

  static Future<FileMagicNumberType> _detectInputType(MergeInput input) async {
    switch (input) {
      case MergeInputPath(:final path):
        return FileMagicNumber.detectFileTypeFromPathOrBlob(path);
      case MergeInputBytes(:final bytes):
        return FileMagicNumber.detectFileTypeFromBytes(bytes);
      default:
        throw UnsupportedError('Unsupported MergeInput subtype: ${input.runtimeType}');
    }
  }

  static Future<Uint8List> _readInputBytes(MergeInput input) async {
    switch (input) {
      case MergeInputPath(:final path):
        return Uint8List.fromList(await File(path).readAsBytes());
      case MergeInputBytes(:final bytes):
        return bytes;
      default:
        throw UnsupportedError('Unsupported MergeInput subtype: ${input.runtimeType}');
    }
  }

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
    if (!PdfCombiner.isMock) {
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

  /// Determines whether the given file path corresponds to a PDF file.
  ///
  /// This method uses the file's magic number (file signature) to accurately
  /// detect if the file is a PDF, regardless of its extension. This is more
  /// reliable than checking only the file extension.
  ///
  /// **Parameters:**
  /// - [filePath]: The absolute path to the file to check
  ///
  /// **Returns:** `true` if the file is a valid PDF, `false` otherwise
  /// (including when an error occurs during detection)
  static Future<bool> isPDF(MergeInput input) async {
    return await _detectInputType(input) == FileMagicNumberType.pdf;
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

  /// Determines whether the given file path corresponds to an image file.
  ///
  /// This method uses the file's magic number (file signature) to detect if
  /// the file is a PNG, JPEG/JPG or HEIC image, regardless of its extension.
  ///
  /// **Currently supported image formats:**
  /// - PNG
  /// - JPEG/JPG
  /// - HEIC
  ///
  /// **Parameters:**
  /// - [input]: The [MergeInput] to check
  ///
  /// **Returns:** `true` if the file is a PNG or JPEG image, `false` otherwise
  /// (including when an error occurs during detection)
  static Future<bool> isImage(MergeInput input) async {
    final fileType = await _detectInputType(input);
    return fileType == FileMagicNumberType.png ||
        fileType == FileMagicNumberType.jpg ||
        fileType == FileMagicNumberType.heic;
  }

  /// Prepares a [MergeInput] for processing.
  ///
  /// If the input is a path, it returns the path as is.
  /// If the input is bytes, it creates a temporary file from the bytes and returns the path to the temporary file.
  ///
  /// **Parameters:**
  /// - [input]: The [MergeInput] to prepare
  ///
  /// **Returns:** The path to the prepared input file
  static Future<String> prepareInput(MergeInput input) async {
    if (input case MergeInputPath(:final path)) {
      return path;
    }

    final bytes = await _readInputBytes(input);
    final fileType = FileMagicNumber.detectFileTypeFromBytes(bytes);
    final tempDirPath = getTemporalFolderPath();
    final tempDir = Directory(tempDirPath);
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    final fileName =
        '${input.temporaryFilePrefix}_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}${fileType.extension()}';
    final tempPath = p.join(tempDirPath, fileName);
    final file = File(tempPath);
    await file.writeAsBytes(bytes);
    return tempPath;
  }
}
