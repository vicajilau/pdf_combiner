import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pdf_combiner_platform_interface.dart';

/// An implementation of [PdfCombinerPlatform] that uses method channels.
class MethodChannelPdfCombiner extends PdfCombinerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pdf_combiner');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  /// Merges multiple PDF files into a single PDF.
  ///
  /// This method sends a request to the native platform to merge the PDF files
  /// specified in the `paths` parameter and saves the result in the `outputPath`.
  ///
  /// Parameters:
  /// - `inputPaths`: A list of file paths of the PDFs to be merged.
  /// - `outputPath`: The directory path where the merged PDF should be saved.
  ///
  /// Returns:
  /// - A `Future<String?>` representing the result of the operation. If the operation
  ///   is successful, it returns a string message from the native platform; otherwise, it returns `null`.
  @override
  Future<String?> mergeMultiplePDFs({
    required List<String> inputPaths,
    required String outputPath,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<String>(
        'mergeMultiplePDF',
        {'paths': inputPaths, 'outputDirPath': outputPath},
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
  /// `outputPath` directory.
  ///
  /// Parameters:
  /// - `inputPaths`: A list of file paths of the images to be converted into a PDF.
  /// - `outputPath`: The directory path where the created PDF should be saved.
  /// - `maxWidth`: The maximum width of each image in the PDF (default is 360).
  /// - `maxHeight`: The maximum height of each image in the PDF (default is 360).
  /// - `needImageCompressor`: Whether to compress images before converting them to PDF (default is `true`).
  ///
  /// Returns:
  /// - A `Future<String?>` representing the result of the operation. If the operation
  ///   is successful, it returns a string message from the native platform; otherwise, it returns `null`.
  @override
  Future<String?> createPDFFromMultipleImages({
    required List<String> inputPaths,
    required String outputPath,
    int? maxWidth,
    int? maxHeight,
    bool? needImageCompressor,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<String>(
        'createPDFFromMultipleImage',
        {
          'paths': inputPaths,
          'outputDirPath': outputPath,
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
  /// - `inputPath`: The file path of the PDF from which images will be extracted.
  /// - `outputPath`: The directory path where the images should be saved.
  /// - `maxWidth`: The maximum width of each extracted image (default is 360).
  /// - `maxHeight`: The maximum height of each extracted image (default is 360).
  /// - `createOneImage`: Whether to create a single image from all PDF pages or separate images for each page (default is `true`).
  ///
  /// Returns:
  /// - A `Future<List<String>?>` representing a list of image file paths. If the operation
  ///   is successful, it returns a list of file paths to the extracted images; otherwise, it returns `null`.
  @override
  Future<List<String>?> createImageFromPDF({
    required String inputPath,
    required String outputPath,
    int? maxWidth,
    int? maxHeight,
    bool? createOneImage,
  }) async {
    try {
      final List<dynamic>? result =
      await methodChannel.invokeMethod<List<dynamic>>(
        'createImageFromPDF',
        {
          'path': inputPath,
          'outputDirPath': outputPath,
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
