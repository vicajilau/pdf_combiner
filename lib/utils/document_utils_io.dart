import 'dart:io';
import 'dart:math';

import 'package:file_magic_number/file_magic_number.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:http/http.dart' as http;
import 'package:pdf_combiner/responses/pdf_combiner_messages.dart';
import 'package:pdf_combiner/utils/string_extension.dart';

extension on MergeInputType {
  String extension(MergeInput input) {
    switch (this) {
      case MergeInputType.path:
        return p.extension(input.path!);
      case MergeInputType.bytes:
        final magicType = FileMagicNumber.detectFileTypeFromBytes(input.bytes);
        return magicType.name;
      case MergeInputType.url:
        return p.extension(input.url!);
    }
  }

  String filenamePrefix() {
    switch (this) {
      case MergeInputType.path:
        return 'pdf_input';
      case MergeInputType.bytes:
        return 'image_input';
      case MergeInputType.url:
        return 'url_input';
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

  /// Converts any `MergeInput.url` entries into temporary `MergeInput.path` files.
  ///
  /// Downloads each URL to a temporary file inside the configured temporal
  /// folder and returns a new list where URLs were replaced by `MergeInput.path`
  /// referencing the downloaded file. `path` and `bytes` inputs are preserved.

  static Future<List<MergeInput>> conversionUrlInputsToPaths(
      List<MergeInput> inputs) async {
    final outputs = <MergeInput>[];
    final tempDirPath = getTemporalFolderPath();
    final tempDir = Directory(tempDirPath);
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }

    for (final input in inputs) {
      switch (input.type) {
        case MergeInputType.path:
          outputs.add(input);
          break;
        case MergeInputType.bytes:
          outputs.add(input);
          break;
        case MergeInputType.url:
          try {
            final response = await http.get(Uri.parse(input.url!));
            if (response.statusCode == 200) {
              final byteInput = MergeInput.bytes(response.bodyBytes);

              final fileName =
                  '${byteInput.type.filenamePrefix()}_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}${byteInput.type.extension(byteInput)}';
              final tempPath = p.join(tempDirPath, fileName);
              final file = File(tempPath);

              await file.writeAsBytes(byteInput.bytes!);

              outputs.add(MergeInput.path(file.path));
            } else {
              throw PdfCombinerException(PdfCombinerMessages.errorMessagePDF(input.url!));
            }
          } catch (e) {
            throw PdfCombinerException(e.toString());
          }

      }
    }
    return outputs;
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
      fileType = input.url!.stringToMagicType;
        break;
    }
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
    switch (input.type) {
      case MergeInputType.path:
        return input.path!;
      case MergeInputType.bytes:
        final tempDirPath = getTemporalFolderPath();
        final tempDir = Directory(tempDirPath);
        if (!await tempDir.exists()) {
          await tempDir.create(recursive: true);
        }
        final fileName =
            '${input.type.filenamePrefix()}_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}${input.type.extension(input)}';
        final tempPath = p.join(tempDirPath, fileName);
        final file = File(tempPath);
        await file.writeAsBytes(input.bytes!);
        return tempPath;
      case MergeInputType.url:
        return input.url!;
    }
  }
}
