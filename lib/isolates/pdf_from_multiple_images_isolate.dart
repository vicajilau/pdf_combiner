import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
    if (kIsWeb) {
      return await compute(_pdfFromMultipleImagesWeb, {
        'inputPaths': inputPaths,
        'outputPath': outputPath,
        'config': config,
      });
    } else {
      final ReceivePort receivePort = ReceivePort();
      await Isolate.spawn(_pdfFromMultipleImages, {
        'sendPort': receivePort.sendPort,
        'inputPaths': inputPaths,
        'outputPath': outputPath,
        'config': config,
        'token': RootIsolateToken.instance!,
      });
      return await receivePort.first as String?;
    }
  }

  /// Background process that creates a PDF from multiple images.
  ///
  /// This function runs in an isolate and communicates back using a [SendPort].
  ///
  /// - `params`: A map containing:
  ///   - `sendPort`: The port to send the result back to the main isolate.
  ///   - `inputPaths`: The list of input image file paths.
  ///   - `outputPath`: The path where the generated PDF should be saved.
  ///   - `config`: Configuration settings for PDF generation.
  ///   - `token`: The isolate token for Flutter's binary messenger.
  static Future<void> _pdfFromMultipleImages(
      Map<String, dynamic> params) async {
    final SendPort sendPort = params['sendPort'];
    final List<String> inputPaths = params['inputPaths'];
    final String outputPath = params['outputPath'];
    final PdfFromMultipleImageConfig config = params['config'];
    final RootIsolateToken token = params['token'];

    BackgroundIsolateBinaryMessenger.ensureInitialized(token);

    final String? response =
        await PdfCombinerPlatform.instance.createPDFFromMultipleImages(
      inputPaths: inputPaths,
      outputPath: outputPath,
      config: config,
    );

    sendPort.send(response);
  }

  /// Background process that creates a PDF from multiple images for Web.
  ///
  /// - `params`: A map containing:
  ///   - `inputPaths`: The list of input image file paths.
  ///   - `outputPath`: The path where the generated PDF should be saved.
  ///   - `config`: Configuration settings for PDF generation.
  static Future<String?> _pdfFromMultipleImagesWeb(
      Map<String, dynamic> params) async {
    final List<String> inputPaths = params['inputPaths'];
    final String outputPath = params['outputPath'];
    final PdfFromMultipleImageConfig config = params['config'];

    return await PdfCombinerPlatform.instance.createPDFFromMultipleImages(
      inputPaths: inputPaths,
      outputPath: outputPath,
      config: config,
    );
  }
}
