import 'package:pdf_combiner/communication/pdf_combiner_platform_interface.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/models/pdf_from_multiple_image_config.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A mock implementation of the [PdfCombinerPlatform] interface for testing purposes.
///
/// This class simulates the platform-specific implementation of the methods in the
/// [PdfCombinerPlatform] interface, allowing you to test the behavior of the PdfCombiner
/// class without requiring access to a real native platform. It returns mock responses
/// for each method.
class MockPdfCombinerPlatform
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
    return Future.value('Merged PDF');
  }

  /// Mocks the `createPDFFromMultipleImage` method.
  ///
  /// Simulates the creation of a PDF from multiple image files. It returns a mock result
  /// indicating that a PDF was created successfully from images.
  ///
  /// [config] The configuration for the PDF creation.
  @override
  Future<String?> createPDFFromMultipleImages({
    required List<String> inputPaths,
    required String outputPath,
    PdfFromMultipleImageConfig config = const PdfFromMultipleImageConfig(),
  }) {
    return Future.value('Created PDF from Images');
  }

  /// Mocks the `createImageFromPDF` method.
  ///
  /// Simulates the creation of images from a PDF file. It returns a mock result
  /// indicating the creation of two image files.
  ///
  /// [inputPath] The path to the PDF file.
  /// [outputPath] The path where the images should be saved.
  /// [config] The configuration for the image creation.
  @override
  Future<List<String>?> createImageFromPDF(
      {required String inputPath,
      required String outputPath,
      ImageFromPdfConfig config = const ImageFromPdfConfig()}) {
    if (config.createOneImage == true) {
      return Future.value(['image1.png']);
    } else {
      return Future.value(['image1.png', 'image2.png']);
    }
  }
}
