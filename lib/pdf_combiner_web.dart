// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:js_util' as js_util;

import 'communication/pdf_combiner_platform_interface.dart';

/// A web implementation of the PdfCombinerPlatform of the PdfCombiner plugin.
class PdfCombinerWeb extends PdfCombinerPlatform {
  /// Constructs a PdfCombinerWeb
  PdfCombinerWeb();

  static void registerWith(Registrar registrar) {
    PdfCombinerPlatform.instance = PdfCombinerWeb();
  }

  @override
  Future<String> mergeMultiplePDFs(
      {required List<String> inputPaths, required String outputPath}) async {
    return await js_util.promiseToFuture(
      js_util.callMethod(
        js_util.getProperty(js_util.globalThis, 'combinePDFs'),
        // Get JS function
        'call',
        [null, js_util.jsify(inputPaths)], // Send converted array
      ),
    );
  }

  @override
  Future<String> createPDFFromMultipleImages(
      {required List<String> inputPaths,
      required String outputPath,
      int? maxWidth,
      int? maxHeight,
      bool? needImageCompressor})  async {
    return await js_util.promiseToFuture(
      js_util.callMethod(
        js_util.getProperty(js_util.globalThis, 'createPdfFromImages'),
        // Get JS function
        'call',
        [null, js_util.jsify(inputPaths)], // Send converted array
      ),
    );
  }

  @override
  Future<List<String>> createImageFromPDF(
      {required String inputPath,
      required String outputPath,
      int? maxWidth,
      int? maxHeight,
      bool? createOneImage}) async {
    String nameFunc = "";
    if(createOneImage == false){
      nameFunc = "convertPdfToImages";
    }else{
      nameFunc = "pdfToImage";
    }
    final result = await js_util.promiseToFuture(
      js_util.callMethod(
        js_util.getProperty(js_util.globalThis, nameFunc),
        // Obtén la función JS
        'call',
        [null,js_util.jsify(inputPath)], // Pasa el array convertido
      ),
    );
    return result.cast<String>();
  }
}
