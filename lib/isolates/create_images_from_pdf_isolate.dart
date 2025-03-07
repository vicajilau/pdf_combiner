import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';

import '../communication/pdf_combiner_platform_interface.dart';

class CreateImagesFromPdfIsolate {
  static Future<List<String>?> createImageFromPDF({
    required String inputPath,
    required String outputDirectory,
    required ImageFromPdfConfig config,
  }) async {
    final ReceivePort receivePort = ReceivePort();

    await Isolate.spawn(_createImageFromPDF, {
      'sendPort': receivePort.sendPort,
      'inputPath': inputPath,
      'outputPath': outputDirectory,
      'config': config,
      'token': RootIsolateToken.instance!,
    });

    return await receivePort.first as List<String>?;
  }

  static Future<void> _createImageFromPDF(Map<String, dynamic> params) async {
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
}
