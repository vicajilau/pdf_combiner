import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'pdf_combiner_platform_interface.dart';

/// Implementation of PdfCombinerPlatform using MethodChannel.
///
/// This class provides the platform-specific implementation for interacting with
/// the native code to perform PDF-related operations, such as merging PDFs, creating
/// PDFs from images, extracting images from PDFs, and retrieving file size information.
/// It uses the `MethodChannel` to communicate with the platform.
class MethodChannelPdfCombiner extends PdfCombinerPlatform {

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('pdf_combiner');

  /// Merges multiple PDF files into a single PDF.
  ///
  /// This method sends a request to the native platform to merge the PDF files
  /// specified in the `paths` parameter and saves the result in the `outputDirPath`.
  ///
  /// Parameters:
  /// - `paths`: A list of file paths of the PDFs to be merged.
  /// - `outputDirPath`: The directory path where the merged PDF should be saved.
  ///
  /// Returns:
  /// - A `Future<String?>` representing the result of the operation. If the operation
  ///   is successful, it returns a string message from the native platform; otherwise, it returns `null`.
  @override
  Future<String?> mergeMultiplePDF({
    required List<String> paths,
    required String outputDirPath,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<String>(
        'mergeMultiplePDF',
        {'paths': paths, 'outputDirPath': outputDirPath},
      );
      return result;
    } catch (e) {
      debugPrint('Error merging PDFs: $e');
      return null;
    }
  }

  /// Creates a PDF from multiple image files.
  ///
  /// This method sends a request to the native platform to create a PDF from the
  /// images specified in the `paths` parameter. The resulting PDF is saved in the
  /// `outputDirPath` directory.
  ///
  /// Parameters:
  /// - `paths`: A list of file paths of the images to be converted into a PDF.
  /// - `outputDirPath`: The directory path where the created PDF should be saved.
  /// - `maxWidth`: The maximum width of each image in the PDF (default is 360).
  /// - `maxHeight`: The maximum height of each image in the PDF (default is 360).
  /// - `needImageCompressor`: Whether to compress images before converting them to PDF (default is `true`).
  ///
  /// Returns:
  /// - A `Future<String?>` representing the result of the operation. If the operation
  ///   is successful, it returns a string message from the native platform; otherwise, it returns `null`.
  @override
  Future<String?> createPDFFromMultipleImage({
    required List<String> paths,
    required String outputDirPath,
    int? maxWidth,
    int? maxHeight,
    bool? needImageCompressor,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<String>(
        'createPDFFromMultipleImage',
        {
          'paths': paths,
          'outputDirPath': outputDirPath,
          'maxWidth': maxWidth ?? 360,
          'maxHeight': maxHeight ?? 360,
          'needImageCompressor': needImageCompressor ?? true,
        },
      );
      return result;
    } catch (e) {
      debugPrint('Error creating PDF from images: $e');
      return null;
    }
  }

  /// Creates images from a PDF file.
  ///
  /// This method sends a request to the native platform to extract images from the
  /// PDF file specified in the `path` parameter and saves the images in the `outputDirPath` directory.
  ///
  /// Parameters:
  /// - `path`: The file path of the PDF from which images will be extracted.
  /// - `outputDirPath`: The directory path where the images should be saved.
  /// - `maxWidth`: The maximum width of each extracted image (default is 360).
  /// - `maxHeight`: The maximum height of each extracted image (default is 360).
  /// - `createOneImage`: Whether to create a single image from all PDF pages or separate images for each page (default is `true`).
  ///
  /// Returns:
  /// - A `Future<List<String>?>` representing a list of image file paths. If the operation
  ///   is successful, it returns a list of file paths to the extracted images; otherwise, it returns `null`.
  @override
  Future<List<String>?> createImageFromPDF({
    required String path,
    required String outputDirPath,
    int? maxWidth,
    int? maxHeight,
    bool? createOneImage,
  }) async {
    try {
      final List<dynamic>? result = await methodChannel.invokeMethod<List<dynamic>>(
        'createImageFromPDF',
        {
          'path': path,
          'outputDirPath': outputDirPath,
          'maxWidth': maxWidth ?? 360,
          'maxHeight': maxHeight ?? 360,
          'createOneImage': createOneImage ?? true,
        },
      );
      return result?.cast<String>();
    } catch (e) {
      debugPrint('Error creating images from PDF: $e');
      return null;
    }
  }
}