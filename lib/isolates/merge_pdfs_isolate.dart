import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/models/pdf_source.dart';

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
  /// - `sources`: A list of [PdfSource] representing the PDFs to be combined.
  /// - `outputPath`: The file path where the merged PDF will be saved.
  ///
  /// Returns the path of the merged PDF, or `null` if an error occurs.
  static Future<String?> mergeMultiplePDFs({
    List<PdfSource>? sources,
    List<String>? inputPaths,
    required String outputPath,
  }) async {
    final List<Map<String, dynamic>> sourcesMap =
        sources?.map((e) => e.toMap()).toList() ??
            inputPaths?.map((e) => {'path': e, 'bytes': null}).toList() ??
            [];

    if (PdfCombiner.isMock) {
      return await PdfCombinerPlatform.instance.mergeMultiplePDFs(
        sources: sourcesMap,
        outputPath: outputPath,
      );
    }
    return await compute(_combinePDFs, {
      'sources': sourcesMap,
      'outputPath': outputPath,
      'token': kIsWeb ? null : RootIsolateToken.instance!,
    });
  }

  /// Background process that merges multiple PDFs.
  ///
  /// - `params`: A map containing:
  ///   - `sources`: The list of input PDF sources (as maps).
  ///   - `outputPath`: The path where the merged PDF should be saved.
  ///   - `token`: The isolate token for Flutter's binary messenger or `null` for web.
  static Future<String?> _combinePDFs(Map<String, dynamic> params) async {
    final List<Map<String, dynamic>> sources =
        (params['sources'] as List).cast<Map<String, dynamic>>();
    final String outputPath = params['outputPath'];
    final RootIsolateToken? token = params['token'];

    if (token != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    }

    return await PdfCombinerPlatform.instance.mergeMultiplePDFs(
      sources: sources,
      outputPath: outputPath,
    );
  }
}
