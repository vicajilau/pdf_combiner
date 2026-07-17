import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/web/list_to_js_array_extension.dart';
import 'package:pdf_combiner/web/pdf_combiner_web_bindings.dart';
import 'package:web/web.dart';

import 'communication/pdf_combiner_platform_interface.dart';
import 'models/image_from_pdf_config.dart';
import 'models/pdf_from_multiple_image_config.dart';
import 'utils/document_utils.dart';

/// Web implementation of the PdfCombinerPlatform.
/// This class handles the interaction between the Flutter app and JavaScript functions
/// for merging PDFs, creating PDFs from images, and converting PDFs to images.
class PdfCombinerWeb extends PdfCombinerPlatform {
  PdfCombinerWeb();

  static Future<void>? _scriptsLoadFuture;

  /// Registers the PdfCombinerWeb instance as the platform implementation.
  /// This method is called by the Flutter framework to link the platform interface
  /// with the web implementation.
  static void registerWith(Registrar registrar) {
    _ensureScriptsLoaded().catchError((Object _) {
      // Ignore failures during initial load to prevent crashes on startup,
      // but they will trigger during function invocations.
    });
    PdfCombinerPlatform.instance = PdfCombinerWeb();
  }

  static Future<void> _ensureScriptsLoaded() {
    if (_scriptsLoadFuture != null) {
      return _scriptsLoadFuture!;
    }

    final completer = Completer<void>();
    _scriptsLoadFuture = completer.future;

    final scripts = [
      'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.min.js',
      'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.worker.min.js',
      'https://cdnjs.cloudflare.com/ajax/libs/pdf-lib/1.17.1/pdf-lib.min.js',
      'https://unpkg.com/heic2any/dist/heic2any.min.js',
      'assets/packages/pdf_combiner/lib/web/assets/js/pdf_combiner.js'
    ];

    int loadedCount = 0;

    void checkDone() {
      loadedCount++;
      if (loadedCount == scripts.length) {
        if (!completer.isCompleted) completer.complete();
      }
    }

    for (final src in scripts) {
      final script = document.createElement('script') as HTMLScriptElement;
      script.src = src;
      script.type = 'text/javascript';

      script.onload = (() {
        checkDone();
      }).toJS;

      script.onerror = ((Event _) {
        if (!completer.isCompleted) {
          completer.completeError(
            Exception('Failed to load dependency script: $src'),
          );
        }
      }).toJS;

      document.head?.appendChild(script);
    }

    return _scriptsLoadFuture!;
  }

  /// Merges multiple PDF files into a single PDF.
  ///
  /// This method sends a request to the native platform to merge the PDF files
  /// specified in the `paths` parameter and saves the result in the `outputPath`.
  ///
  /// Parameters:
  /// - `inputs`: A list of file paths of the PDFs to be merged.
  /// - `outputPath`: The directory path where the merged PDF should be saved.
  ///
  /// Returns:
  /// - A `Future<String?>` representing the result of the operation. If the operation
  ///   is successful, it returns a string message from the native platform; otherwise, it returns `null`.
  @override
  Future<String> mergeMultiplePDFs({
    required List<MergeInput> inputs,
    required String outputPath,
  }) async {
    await _ensureScriptsLoaded();
    final inputPaths = await Future.wait(inputs.map(
        (MergeInput input) async => await DocumentUtils.prepareInput(input)));
    final JSArray<JSString> jsInputPaths = inputPaths.toJSArray();
    final JSString result =
        (await combinePDFs(jsInputPaths).toDart) as JSString;
    return result.toDart;
  }

  /// Creates a PDF from multiple image files.
  ///
  /// This method sends a request to the native platform to create a PDF from the
  /// images specified in the `inputs` parameter. The resulting PDF is saved in the
  /// `outputPath` directory.
  ///
  /// Parameters:
  /// - `inputs`: A list of MergeInput to be converted into a PDF.
  /// - `outputPath`: The directory path where the created PDF should be saved.
  /// - `config`: A configuration object that specifies how to process the images.
  ///   - `rescale`: The scaling configuration for the images (default is the original image).
  ///   - `keepAspectRatio`: Indicates whether to maintain the aspect ratio of the images (default is `true`).
  ///
  /// Returns:
  /// - A `Future<String?>` representing the result of the operation. If the operation
  ///   is successful, it returns a string message from the native platform; otherwise, it returns `null`.
  @override
  Future<String> createPDFFromMultipleImages({
    required List<MergeInput> inputs,
    required String outputPath,
    PdfFromMultipleImageConfig config = const PdfFromMultipleImageConfig(),
  }) async {
    await _ensureScriptsLoaded();
    final inputPaths = await Future.wait(inputs.map(
        (MergeInput input) async => await DocumentUtils.prepareInput(input)));
    final JSArray<JSString> jsInputPaths = inputPaths.toJSArray();
    final JSString result =
        (await createPdfFromImages(jsInputPaths, config.toMap().jsify()).toDart)
            as JSString;
    return result.toDart;
  }

  /// Creates images from a PDF file.
  ///
  /// This method sends a request to the native platform to extract images from the
  /// PDF file specified in the `path` parameter and saves the images in the `outputDirPath` directory.
  ///
  /// Parameters:
  /// - `input`: The input to be converted into images.
  /// - `outputPath`: The directory path where the images should be saved.
  /// - `config`: A configuration object that specifies how to process the images.
  ///   - `rescale`: The scaling configuration for the images (default is the original image).
  ///   - `compression`: The image compression level for compression, affecting file size quality and clarity (default is [ImageCompression.none]).
  ///   - `createOneImage`: Indicates whether to create a single image or separate images for each page (default is `true`).
  ///
  /// Returns:
  /// - A `Future<List<String>?>` representing a list of image file paths. If the operation
  ///   is successful, it returns a list of file paths to the extracted images; otherwise, it returns `null`.
  @override
  Future<List<String>> createImageFromPDF({
    required MergeInput input,
    required String outputPath,
    ImageFromPdfConfig config = const ImageFromPdfConfig(),
  }) async {
    await _ensureScriptsLoaded();
    final String inputPath = await DocumentUtils.prepareInput(input);
    final JSString jsInputPath = inputPath.toJS;
    final JSArray<JSString> result = config.createOneImage
        ? (await pdfToImage(jsInputPath, config.jsify()).toDart)
            as JSArray<JSString>
        : (await convertPdfToImages(jsInputPath, config.jsify()).toDart)
            as JSArray<JSString>;
    return result.toList();
  }
}
