import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pdf_combiner_method_channel.dart';

/// Abstract class that serves as the platform interface for PdfCombiner.
///
/// This class defines the methods that should be implemented by platform-specific
/// code to interact with the native code for PDF-related operations, such as merging
/// PDFs, creating PDFs from images, extracting images from PDFs, retrieving file sizes,
/// and fetching build information.
abstract class PdfCombinerPlatform extends PlatformInterface {
  /// Constructs a PdfCombinerPlatform.
  PdfCombinerPlatform() : super(token: _token);

  static final Object _token = Object();

  static PdfCombinerPlatform _instance = MethodChannelPdfCombiner();

  /// The default instance of [PdfCombinerPlatform] to use.
  ///
  /// This getter returns the default platform implementation (usually [MethodChannelPdfCombiner]).
  /// Platform-specific implementations should set this to their own class that extends [PdfCombinerPlatform].
  static PdfCombinerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PdfCombinerPlatform] when
  /// they register themselves.
  static set instance(PdfCombinerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Combines multiple PDFs into a single PDF.
  ///
  /// Platform-specific implementations should override this method to merge
  /// multiple PDFs and return the result.
  ///
  /// Parameters:
  /// - `paths`: A list of file paths of the PDFs to be merged.
  /// - `outputDirPath`: The directory path where the merged PDF should be saved.
  ///
  /// Returns:
  /// - A `Future<String?>` representing the result of the operation. By default,
  ///   this throws an [UnimplementedError].
  Future<String?> mergeMultiplePDF({
    required List<String> paths,
    required String outputDirPath,
  }) {
    throw UnimplementedError('mergeMultiplePDF() has not been implemented.');
  }

  /// Creates a PDF from multiple image files.
  ///
  /// Platform-specific implementations should override this method to create a
  /// PDF from images and return the result.
  ///
  /// Parameters:
  /// - `paths`: A list of file paths of the images to be converted into a PDF.
  /// - `outputDirPath`: The directory path where the created PDF should be saved.
  /// - `maxWidth`: The maximum width of each image in the PDF (default is 360).
  /// - `maxHeight`: The maximum height of each image in the PDF (default is 360).
  /// - `needImageCompressor`: Whether to compress images before converting them to PDF (default is `true`).
  ///
  /// Returns:
  /// - A `Future<String?>` representing the result of the operation. By default,
  ///   this throws an [UnimplementedError].
  Future<String?> createPDFFromMultipleImage({
    required List<String> paths,
    required String outputDirPath,
    int? maxWidth,
    int? maxHeight,
    bool? needImageCompressor,
  }) {
    throw UnimplementedError(
        'createPDFFromMultipleImage() has not been implemented.');
  }

  /// Creates images from a PDF file.
  ///
  /// Platform-specific implementations should override this method to extract images
  /// from the provided PDF and return the resulting image file paths.
  ///
  /// Parameters:
  /// - `path`: The file path of the PDF from which images will be extracted.
  /// - `outputDirPath`: The directory path where the images should be saved.
  /// - `maxWidth`: The maximum width of each extracted image (default is 360).
  /// - `maxHeight`: The maximum height of each extracted image (default is 360).
  /// - `createOneImage`: Whether to create a single image from all PDF pages or separate images for each page (default is `true`).
  ///
  /// Returns:
  /// - A `Future<List<String>?>` representing a list of image file paths. By default,
  ///   this throws an [UnimplementedError].
  Future<List<String>?> createImageFromPDF({
    required String path,
    required String outputDirPath,
    int? maxWidth,
    int? maxHeight,
    bool? createOneImage,
  }) {
    throw UnimplementedError('createImageFromPDF() has not been implemented.');
  }

  /// Gets the size of a file at the specified path.
  ///
  /// Platform-specific implementations should override this method to retrieve
  /// the size of the file at the given path.
  ///
  /// Parameters:
  /// - `path`: The file path of the file whose size needs to be retrieved.
  ///
  /// Returns:
  /// - A `Future<String?>` representing the file size as a string. By default,
  ///   this throws an [UnimplementedError].
  Future<String?> sizeForPath(String path) {
    throw UnimplementedError('sizeForPath() has not been implemented.');
  }

  /// Retrieves build information, such as version name and build date.
  ///
  /// Platform-specific implementations should override this method to retrieve
  /// the build information from the native platform.
  ///
  /// Returns:
  /// - A `Future<Map<String, String>>` representing the build information
  ///   as a map of string key-value pairs (e.g., version name, build date).
  ///   By default, this throws an [UnimplementedError].
  Future<Map<String, String>> buildInfo() {
    throw UnimplementedError('buildInfo() has not been implemented.');
  }
}
