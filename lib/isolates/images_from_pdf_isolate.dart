import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';

import '../communication/pdf_combiner_platform_interface.dart';

/// Internal class for handling image extraction from PDFs using isolates.
///
/// This class should not be used directly. It manages the process of creating
/// images from a PDF file in a separate isolate to prevent blocking the main thread.
class ImagesFromPdfIsolate {
  /// Creates images from a PDF file in a separate isolate.
  ///
  /// This method spawns an isolate (or uses `compute` on the web) to process
  /// the PDF asynchronously.
  ///
  /// - `inputPath`: The path to the input PDF file.
  /// - `outputDirectory`: The directory where the extracted images will be saved.
  /// - `config`: Configuration options for the image extraction process.
  ///
  /// Returns a list of file paths of the extracted images, or `null` if an error occurs.
  static Future<List<String>?> createImageFromPDF({
    required String inputPath,
    required String outputDirectory,
    required ImageFromPdfConfig config,
  }) async {
    if (PdfCombiner.isMock) {
      return await PdfCombinerPlatform.instance.createImageFromPDF(
        input: MergeInput.path(inputPath),
        outputPath: outputDirectory,
        config: config,
      );
    }
    return await compute(_createImageFromPdf, {
      'inputPath': inputPath,
      'outputDirectory': outputDirectory,
      'config': config,
      'token': kIsWeb ? null : RootIsolateToken.instance!,
    });
  }

  /// Background process that extracts images from a PDF file.
  ///
  /// - `params`: A map containing:
  ///   - `inputPath`: The path of the input PDF file.
  ///   - `outputDirectory`: The path where images should be saved.
  ///   - `config`: The configuration for extraction.
  ///   - `token`: The isolate token for Flutter's binary messenger or `null` for web.
  static Future<List<String>?> _createImageFromPdf(
      Map<String, dynamic> params) async {
    final String inputPath = params['inputPath'];
    final String outputDirectory = params['outputDirectory'];
    final ImageFromPdfConfig config = params['config'];
    final RootIsolateToken? token = params['token'];

    if (token != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    }

    return await PdfCombinerPlatform.instance.createImageFromPDF(
      input: MergeInput.path(inputPath),
      outputPath: outputDirectory,
      config: config,
    );
  }
}
