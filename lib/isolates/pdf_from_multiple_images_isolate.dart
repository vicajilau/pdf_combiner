import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';

import '../communication/pdf_combiner_platform_interface.dart';
import '../models/pdf_from_multiple_image_config.dart';

/// Internal class for handling PDF creation from multiple images using isolates.
///
/// This class should not be used directly. It manages the process of converting
/// multiple images into a PDF in a separate isolate to prevent blocking the main thread.
class PdfFromMultipleImagesIsolate {
  /// Creates a PDF from multiple images in a separate isolate.
  ///
  /// This method spawns an isolate (or uses `compute` on the web) to process
  /// the PDF creation asynchronously.
  ///
  /// - `inputPaths`: A list of file paths of the input images.
  /// - `outputPath`: The file path where the generated PDF will be saved.
  /// - `config`: Configuration settings for PDF generation.
  ///
  /// Returns the path of the generated PDF, or `null` if an error occurs.
  static Future<String?> createPDFFromMultipleImages({
    required List<String> inputPaths,
    required String outputPath,
    required PdfFromMultipleImageConfig config,
  }) async {
    if (PdfCombiner.isMock) {
      return await PdfCombinerPlatform.instance.createPDFFromMultipleImages(
        inputs: inputPaths.map((e) => MergeInput.path(e)).toList(),
        outputPath: outputPath,
        config: config,
      );
    }
    return await compute(_pdfFromMultipleImages, {
      'inputPaths': inputPaths,
      'outputPath': outputPath,
      'config': config,
      'token': kIsWeb ? null : RootIsolateToken.instance!,
    });
  }

  /// Background process that creates a PDF from multiple images.
  ///
  /// - `params`: A map containing:
  ///   - `inputPaths`: The list of input image file paths.
  ///   - `outputPath`: The path where the generated PDF should be saved.
  ///   - `config`: Configuration settings for PDF generation.
  ///   - `token`: The isolate token for Flutter's binary messenger or `null` for web.
  static Future<String?> _pdfFromMultipleImages(
      Map<String, dynamic> params) async {
    final List<String> inputPaths = params['inputPaths'];
    final String outputPath = params['outputPath'];
    final PdfFromMultipleImageConfig config = params['config'];
    final RootIsolateToken? token = params['token'];

    if (token != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    }

    return await PdfCombinerPlatform.instance.createPDFFromMultipleImages(
      inputs: inputPaths.map((e) => MergeInput.path(e)).toList(),
      outputPath: outputPath,
      config: config,
    );
  }
}
