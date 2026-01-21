import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';

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
  /// - `inputs`: A list of file paths of the input PDFs.
  /// - `outputPath`: The file path where the merged PDF will be saved.
  ///
  /// Returns the path of the merged PDF, or `null` if an error occurs.
  static Future<String?> mergeMultiplePDFs({
    required List<String> inputPaths,
    required String outputPath,
  }) async {
    if (PdfCombiner.isMock) {
      return await PdfCombinerPlatform.instance.mergeMultiplePDFs(
        inputs: inputPaths.map((e) => MergeInput.path(e)).toList(),
        outputPath: outputPath,
      );
    }
    return await compute(_combinePDFs, {
      'inputPaths': inputPaths,
      'outputPath': outputPath,
      'token': kIsWeb ? null : RootIsolateToken.instance!,
    });
  }

  /// Background process that merges multiple PDFs.
  ///
  /// - `params`: A map containing:
  ///   - `inputPaths`: The list of input PDF file paths.
  ///   - `outputPath`: The path where the merged PDF should be saved.
  ///   - `token`: The isolate token for Flutter's binary messenger or `null` for web.
  static Future<String?> _combinePDFs(Map<String, dynamic> params) async {
    final List<String> inputPaths = params['inputPaths'];
    final String outputPath = params['outputPath'];
    final RootIsolateToken? token = params['token'];

    if (token != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    }

    return await PdfCombinerPlatform.instance.mergeMultiplePDFs(
      inputs: inputPaths.map((e) => MergeInput.path(e)).toList(),
      outputPath: outputPath,
    );
  }
}
