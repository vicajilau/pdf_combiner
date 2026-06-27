import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_messages.dart';
import 'package:pdf_combiner/utils/document_utils.dart';

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
    required List<MergeInput> inputs,
    required String outputPath,
  }) async {
    if (PdfCombiner.isMock) {
      final error = await _validate(inputs, outputPath);
      if (error != null) return error;

      return await PdfCombinerPlatform.instance.mergeMultiplePDFs(
        inputs: inputs,
        outputPath: outputPath,
      );
    }
    return await compute(_combinePDFs, {
      'inputs': inputs,
      'outputPath': outputPath,
      'token': kIsWeb ? null : RootIsolateToken.instance!,
    });
  }

  static Future<String?> _validate(
      List<MergeInput> inputs, String outputPath) async {

    final outputPathIsPDF = DocumentUtils.hasPDFExtension(outputPath);
    if (!outputPathIsPDF) {
      return PdfCombinerMessages.errorMessageInvalidOutputPath(outputPath);
    }
    return null;
  }

  /// Background process that merges multiple PDFs.
  ///
  /// - `params`: A map containing:
  ///   - `inputPaths`: The list of input PDF file paths.
  ///   - `outputPath`: The path where the merged PDF should be saved.
  ///   - `token`: The isolate token for Flutter's binary messenger or `null` for web.
  static Future<String?> _combinePDFs(Map<String, dynamic> params) async {
    final List<MergeInput> inputs = params['inputs'];
    final String outputPath = params['outputPath'];
    final RootIsolateToken? token = params['token'];
    final temporalFilePaths = <String>[];

    if (token != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    }

    try {
      final error = await _validate(inputs, outputPath);
      if (error != null) return error;

      final inputPaths = await Future.wait(
        inputs.map(
          (input) async {
            final result = await DocumentUtils.prepareInput(input);
            if (input.type == MergeInputType.bytes) {
              temporalFilePaths.add(result);
            }
            return result;
          },
        ),
      );

      return await PdfCombinerPlatform.instance.mergeMultiplePDFs(
        inputs: inputPaths.map((e) => MergeInput.path(e)).toList(),
        outputPath: outputPath,
      );
    } finally {
      DocumentUtils.removeTemporalFiles(temporalFilePaths);
    }
  }
}
