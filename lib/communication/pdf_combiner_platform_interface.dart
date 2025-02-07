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
  /// - `inputPaths`: A list of file paths of the PDFs to be merged.
  /// - `outputDirPath`: The directory path where the merged PDF should be saved.
  ///
  /// Returns:
  /// - A `Future<String?>` representing the result of the operation. By default,
  ///   this throws an [UnimplementedError].
  Future<String?> mergeMultiplePDFs({
    required List<String> inputPaths,
    required String outputPath,
  }) {
    throw UnimplementedError('mergeMultiplePDF() has not been implemented.');
  }

  /// Creates a PDF from multiple image files.
  ///
  /// Platform-specific implementations should override this method to create a
  /// PDF from images and return the result.
  ///
  /// Parameters:
  /// - `inputPaths`: A list of file paths of the images to be converted into a PDF.
  /// - `outputPath`: The directory path where the created PDF should be saved.
  /// - `maxWidth`: The maximum width of each image in the PDF (default is 360).
  /// - `maxHeight`: The maximum height of each image in the PDF (default is 360).
  /// - `needImageCompressor`: Whether to compress images before converting them to PDF (default is `true`).
  ///
  /// Returns:
  /// - A `Future<String?>` representing the result of the operation. By default,
  ///   this throws an [UnimplementedError].
  Future<String?> createPDFFromMultipleImages({
    required List<String> inputPaths,
    required String outputPath,
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
  /// - `inputPath`: The file path of the PDF from which images will be extracted.
  /// - `outputPath`: The directory path where the images should be saved.
  /// - `maxWidth`: The maximum width of each extracted image (default is 360).
  /// - `maxHeight`: The maximum height of each extracted image (default is 360).
  /// - `createOneImage`: Whether to create a single image from all PDF pages or separate images for each page (default is `true`).
  ///
  /// Returns:
  /// - A `Future<List<String>?>` representing a list of image file paths. By default,
  ///   this throws an [UnimplementedError].
  Future<List<String>?> createImageFromPDF({
    required String inputPath,
    required String outputPath,
    int maxWidth = 360,
    int maxHeight = 360,
    bool createOneImage = true,
  }) {
    throw UnimplementedError('createImageFromPDF() has not been implemented.');
  }
}
