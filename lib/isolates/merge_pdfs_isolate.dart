import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../communication/pdf_combiner_platform_interface.dart';

/// Internal class for handling PDF merging using isolates.
///
/// This class should not be used directly. It manages the process of merging
/// multiple PDFs in a separate isolate to prevent blocking the main thread.
class MergePdfsIsolate {
  /// Merges multiple PDFs into a single file in a separate isolate.
  ///
  /// This method spawns an isolate (or uses `compute` on the web) to process
  /// the PDF merging asynchronously.
  ///
  /// - `inputPaths`: A list of file paths of the input PDFs.
  /// - `outputPath`: The file path where the merged PDF will be saved.
  ///
  /// Returns the path of the merged PDF, or `null` if an error occurs.
  static Future<String?> mergeMultiplePDFs({
    required List<String> inputPaths,
    required String outputPath,
  }) async {
    final ReceivePort receivePort = ReceivePort();

    if (kIsWeb) {
      await compute(_combinePDFs, {
        'sendPort': receivePort.sendPort,
        'inputPaths': inputPaths,
        'outputPath': outputPath,
        'token': RootIsolateToken.instance!,
      });
    } else {
      await Isolate.spawn(_combinePDFs, {
        'sendPort': receivePort.sendPort,
        'inputPaths': inputPaths,
        'outputPath': outputPath,
        'token': RootIsolateToken.instance!,
      });
    }
    return await receivePort.first as String?;
  }

  /// Background process that merges multiple PDFs.
  ///
  /// This function runs in an isolate and communicates back using a [SendPort].
  ///
  /// - `params`: A map containing:
  ///   - `sendPort`: The port to send the result back to the main isolate.
  ///   - `inputPaths`: The list of input PDF file paths.
  ///   - `outputPath`: The path where the merged PDF should be saved.
  ///   - `token`: The isolate token for Flutter's binary messenger.
  static Future<void> _combinePDFs(Map<String, dynamic> params) async {
    final SendPort sendPort = params['sendPort'];
    final List<String> inputPaths = params['inputPaths'];
    final String outputPath = params['outputPath'];
    final RootIsolateToken token = params['token'];

    BackgroundIsolateBinaryMessenger.ensureInitialized(token);

    final String? response =
        await PdfCombinerPlatform.instance.mergeMultiplePDFs(
      inputPaths: inputPaths,
      outputPath: outputPath,
    );

    sendPort.send(response);
  }
}
