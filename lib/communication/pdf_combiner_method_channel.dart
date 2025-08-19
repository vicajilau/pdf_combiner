import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';

import '../models/pdf_from_multiple_image_config.dart';
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
    final result = await methodChannel.invokeMethod<String>(
      'mergeMultiplePDF',
      {'paths': inputPaths, 'outputDirPath': outputPath},
    );
    return result;
  }

  /// Creates a PDF from multiple image files.
  ///
  /// This method sends a request to the native platform to create a PDF from the
  /// images specified in the `inputPaths` parameter. The resulting PDF is saved in the
  /// `outputPath` directory.
  ///
  /// Parameters:
  /// - `inputPaths`: A list of file paths of the images to be converted into a PDF.
  /// - `outputPath`: The directory path where the created PDF should be saved.
  /// - `config`: A configuration object that specifies how to process the images.
  ///   - `rescale`: The scaling configuration for the images (default is the original image).
  ///   - `keepAspectRatio`: Indicates whether to maintain the aspect ratio of the images (default is `true`).
  ///
  /// Returns:
  /// - A `Future<String?>` representing the result of the operation. If the operation
  ///   is successful, it returns a string message from the native platform; otherwise, it returns `null`.
  @override
  Future<String?> createPDFFromMultipleImages({
    required List<String> inputPaths,
    required String outputPath,
    PdfFromMultipleImageConfig config = const PdfFromMultipleImageConfig(),
  }) async {
    final result = await methodChannel.invokeMethod<String>(
      'createPDFFromMultipleImage',
      {
        'paths': inputPaths,
        'outputDirPath': outputPath,
        'height': config.rescale.height,
        'width': config.rescale.width,
        'keepAspectRatio': config.keepAspectRatio,
      },
    );
    return result;
  }

  /// Creates images from a PDF file.
  ///
  /// This method sends a request to the native platform to extract images from the
  /// PDF file specified in the `path` parameter and saves the images in the `outputDirPath` directory.
  ///
  /// Parameters:
  /// - `inputPath`: The file path of the PDF from which images will be extracted.
  /// - `outputPath`: The directory path where the images should be saved.
  /// - `config`: A configuration object that specifies how to process the images.
  ///   - `rescale`: The scaling configuration for the images (default is the original image).
  ///   - `compression`: The image compression level for the images, affecting file size, quality and clarity (default is [ImageCompression.none]).
  ///   - `createOneImage`: Indicates whether to create a single image or separate images for each page (default is `true`).
  ///
  /// Returns:
  /// - A `Future<List<String>?>` representing a list of image file paths. If the operation
  ///   is successful, it returns a list of file paths to the extracted images; otherwise, it returns `null`.
  @override
  Future<List<String>?> createImageFromPDF({
    required String inputPath,
    required String outputPath,
    ImageFromPdfConfig config = const ImageFromPdfConfig(),
  }) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'createImageFromPDF',
      {
        'path': inputPath,
        'outputDirPath': outputPath,
        'height': config.rescale.height,
        'width': config.rescale.width,
        'compression': config.compression.value,
        'createOneImage': config.createOneImage,
      },
    );
    return result?.cast<String>();
  }
}
