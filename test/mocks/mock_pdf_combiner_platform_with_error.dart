import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mock_pdf_combiner_platform.dart';

/// A mock platform that simulates an error when calling the [mergeMultiplePDF] method.
/// It extends [MockPdfCombinerPlatform] and overrides the [mergeMultiplePDF] method
/// to return an error instead of a successful result.
class MockPdfCombinerPlatformWithError
    with MockPlatformInterfaceMixin
    implements PdfCombinerPlatform {
  /// Mocks the `mergeMultiplePDF` method.
  ///
  /// Simulates combining multiple PDFs into a single PDF. It returns a mock result
  /// indicating a successful merge.
  ///
  /// [inputPaths] A list of file paths to the PDF files to be merged.
  /// [outputPath] The path where the merged PDF should be saved.
  @override
  Future<String?> mergeMultiplePDFs({
    required List<String> inputPaths,
    required String outputPath,
  }) {
    return Future.value('error');
  }

  /// Mocks the `createPDFFromMultipleImage` method.
  ///
  /// Simulates the creation of a PDF from multiple image files. It returns a mock result
  /// indicating that a PDF was created successfully from images.
  ///
  /// [inputPaths] A list of file paths to the images.
  /// [outputPath] The path where the created PDF should be saved.
  /// [maxWidth] The maximum width for resizing the images (optional).
  /// [maxHeight] The maximum height for resizing the images (optional).
  /// [needImageCompressor] Whether to compress the images (optional).
  @override
  Future<String?> createPDFFromMultipleImages({
    required List<String> inputPaths,
    required String outputPath,
    int? maxWidth,
    int? maxHeight,
    bool? needImageCompressor,
  }) {
    return Future.value('error');
  }

  /// Mocks the `createImageFromPDF` method.
  ///
  /// Simulates the creation of images from a PDF file. It returns a mock result
  /// indicating the creation of two image files.
  ///
  /// [inputPath] The path to the PDF file.
  /// [outputPath] The path where the images should be saved.
  /// [maxWidth] The maximum width for resizing the images (optional).
  /// [maxHeight] The maximum height for resizing the images (optional).
  /// [createOneImage] Whether to create a single image from the entire PDF (optional).
  @override
  Future<List<String>?> createImageFromPDF({
    required String inputPath,
    required String outputPath,
    int? maxWidth,
    int? maxHeight,
    bool? createOneImage,
  }) {
    throw Exception("Mocked Exception");
  }
}
