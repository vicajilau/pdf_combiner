import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';

import '../communication/pdf_combiner_platform_interface.dart';
import '../models/pdf_from_multiple_image_config.dart';

class PdfFromMultipleImagesIsolate {
  static Future<String?> createPDFFromMultipleImages({
    required List<String> inputPaths,
    required String outputPath,
    required PdfFromMultipleImageConfig config,
  }) async {
    final ReceivePort receivePort = ReceivePort();

    await Isolate.spawn(_combinePDFs, {
      'sendPort': receivePort.sendPort,
      'inputPaths': inputPaths,
      'outputPath': outputPath,
      'config': config,
      'token': RootIsolateToken.instance!,
    });

    return await receivePort.first as String?;
  }

  static Future<void> _combinePDFs(Map<String, dynamic> params) async {
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
}
