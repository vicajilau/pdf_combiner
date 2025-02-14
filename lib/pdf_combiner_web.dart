import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:pdf_combiner/web/list_to_js_array_extension.dart';
import 'package:pdf_combiner/web/pdf_combiner_web_bindings.dart';

import 'communication/pdf_combiner_platform_interface.dart';

/// Web implementation of the PdfCombinerPlatform.
/// This class handles the interaction between the Flutter app and JavaScript functions
/// for merging PDFs, creating PDFs from images, and converting PDFs to images.
class PdfCombinerWeb extends PdfCombinerPlatform {
  PdfCombinerWeb();

  /// Registers the PdfCombinerWeb instance as the platform implementation.
  /// This method is called by the Flutter framework to link the platform interface
  /// with the web implementation.
  static void registerWith(Registrar registrar) {
    PdfCombinerPlatform.instance = PdfCombinerWeb();
  }

  /// Merges multiple PDFs into one PDF.
  ///
  /// Takes a list of input file paths and an output path, and returns the path of the
  /// merged PDF as a string.
  ///
  /// [inputPaths] - List of paths to the input PDF files.
  /// [outputPath] - The path where the merged PDF will be saved.
  @override
  Future<String> mergeMultiplePDFs({
    required List<String> inputPaths,
    required String outputPath,
  }) async {
    final JSArray<JSString> jsInputPaths = inputPaths.toJSArray();
    final JSString result =
        (await combinePDFs(jsInputPaths).toDart) as JSString;
    return result.toDart;
  }

  /// Creates a single PDF from multiple images.
  ///
  /// Takes a list of input image file paths and an output path, and returns the path
  /// to the generated PDF.
  ///
  /// [inputPaths] - List of paths to the input image files.
  /// [outputPath] - The path where the created PDF will be saved.
  /// [maxWidth] - Optional maximum width of the images in the output PDF (default is 360).
  /// [maxHeight] - Optional maximum height of the images in the output PDF (default is 360).
  /// [needImageCompressor] - Optional flag to indicate whether to compress the images.
  @override
  Future<String> createPDFFromMultipleImages({
    required List<String> inputPaths,
    required String outputPath,
    int? maxWidth,
    int? maxHeight,
    bool? needImageCompressor,
  }) async {
    final JSArray<JSString> jsInputPaths = inputPaths.toJSArray();
    final JSString result =
        (await createPdfFromImages(jsInputPaths).toDart) as JSString;
    return result.toDart;
  }

  /// Creates an image or multiple images from a PDF file.
  ///
  /// Converts a PDF to either a single image or multiple images based on the `createOneImage` flag.
  ///
  /// [inputPath] - The path to the input PDF file.
  /// [outputPath] - The output path where the image(s) will be saved.
  /// [maxWidth] - Optional maximum width of the image(s) (default is 360).
  /// [maxHeight] - Optional maximum height of the image(s) (default is 360).
  /// [createOneImage] - A flag indicating whether to create one image (true) or multiple images (false).
  @override
  Future<List<String>> createImageFromPDF({
    required String inputPath,
    required String outputPath,
    int maxWidth = 360,
    int maxHeight = 360,
    bool createOneImage = true,
  }) async {
    final JSString jsInputPath = inputPath.toJS;
    final JSArray<JSString> result = createOneImage
        ? (await pdfToImage(jsInputPath).toDart) as JSArray<JSString>
        : (await convertPdfToImages(jsInputPath).toDart) as JSArray<JSString>;
    return result.toList();
  }
}
