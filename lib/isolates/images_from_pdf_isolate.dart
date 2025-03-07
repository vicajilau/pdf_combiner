import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';

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
    if (kIsWeb) {
      return await compute(_createImageFromPdfWeb, {
        'inputPath': inputPath,
        'outputPath': outputDirectory,
        'config': config,
      });
    } else {
      final ReceivePort receivePort = ReceivePort();
      await Isolate.spawn(_createImageFromPdf, {
        'sendPort': receivePort.sendPort,
        'inputPath': inputPath,
        'outputPath': outputDirectory,
        'config': config,
        'token': RootIsolateToken.instance!,
      });
      return await receivePort.first as List<String>?;
    }
  }

  /// Background process that extracts images from a PDF file.
  ///
  /// This function runs in an isolate and communicates back using a [SendPort].
  ///
  /// - `params`: A map containing:
  ///   - `sendPort`: The port to send the result back to the main isolate.
  ///   - `inputPath`: The path of the input PDF file.
  ///   - `outputDirectory`: The path where images should be saved.
  ///   - `config`: The configuration for extraction.
  ///   - `token`: The isolate token for Flutter's binary messenger.
  static Future<void> _createImageFromPdf(Map<String, dynamic> params) async {
    final SendPort sendPort = params['sendPort'];
    final String inputPath = params['inputPath'];
    final String outputDirectory = params['outputDirectory'];
    final ImageFromPdfConfig config = params['config'];
    final RootIsolateToken token = params['token'];

    BackgroundIsolateBinaryMessenger.ensureInitialized(token);

    final response = await PdfCombinerPlatform.instance.createImageFromPDF(
      inputPath: inputPath,
      outputPath: outputDirectory,
      config: config,
    );

    sendPort.send(response);
  }

  /// Background process that extracts images from a PDF file for web.
  ///
  /// - `params`: A map containing:
  ///   - `inputPath`: The path of the input PDF file.
  ///   - `outputDirectory`: The path where images should be saved.
  ///   - `config`: The configuration for extraction.
  static Future<List<String>?> _createImageFromPdfWeb(
      Map<String, dynamic> params) async {
    final String inputPath = params['inputPath'];
    final String outputDirectory = params['outputDirectory'];
    final ImageFromPdfConfig config = params['config'];

    return await PdfCombinerPlatform.instance.createImageFromPDF(
      inputPath: inputPath,
      outputPath: outputDirectory,
      config: config,
    );
  }
}
