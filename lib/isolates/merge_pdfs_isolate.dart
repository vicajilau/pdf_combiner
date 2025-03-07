import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';

import '../communication/pdf_combiner_platform_interface.dart';

class MergePdfsIsolate {
  static Future<String?> mergeMultiplePDFs({
    required List<String> inputPaths,
    required String outputPath,
  }) async {
    final ReceivePort receivePort = ReceivePort();

    await Isolate.spawn(_combinePDFs, {
      'sendPort': receivePort.sendPort,
      'inputPaths': inputPaths,
      'outputPath': outputPath,
      'token': RootIsolateToken.instance!,
    });

    return await receivePort.first as String?;
  }

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
