import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:pdf_combiner/web/list_to_js_array_extension.dart';
import 'package:pdf_combiner/web/pdf_combiner_web_bindings.dart';
import 'package:web/web.dart';

import 'communication/pdf_combiner_platform_interface.dart';
import 'models/image_from_pdf_config.dart';
import 'models/pdf_from_multiple_image_config.dart';

/// Web implementation of the PdfCombinerPlatform.
/// This class handles the interaction between the Flutter app and JavaScript functions
/// for merging PDFs, creating PDFs from images, and converting PDFs to images.
class PdfCombinerWeb extends PdfCombinerPlatform {
  PdfCombinerWeb();

  /// Registers the PdfCombinerWeb instance as the platform implementation.
  /// This method is called by the Flutter framework to link the platform interface
  /// with the web implementation.
  static void registerWith(Registrar registrar) {
    _loadJsScripts();
    PdfCombinerPlatform.instance = PdfCombinerWeb();
  }

  static void _loadJsScripts() {
    final pdfMinScript = document.createElement('script');
    final pdfWorkerScript = document.createElement('script');
    final pdfLibScript = document.createElement('script');
    final pdfCombinerScript = document.createElement('script');

    pdfMinScript.setAttribute('src',
        'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.min.js');
    pdfMinScript.setAttribute('type', 'text/javascript');
    pdfWorkerScript.setAttribute('src',
        'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.worker.min.js');
    pdfWorkerScript.setAttribute('type', 'text/javascript');
    pdfLibScript.setAttribute('src',
        'https://cdnjs.cloudflare.com/ajax/libs/pdf-lib/1.17.1/pdf-lib.min.js');
    pdfLibScript.setAttribute('type', 'text/javascript');
    pdfCombinerScript.setAttribute('src',
        'assets/packages/pdf_combiner/lib/web/assets/js/pdf_combiner.js');
    pdfCombinerScript.setAttribute('type', 'text/javascript');

    document.head?.appendChild(pdfMinScript);
    document.head?.appendChild(pdfWorkerScript);
    document.head?.appendChild(pdfLibScript);
    document.head?.appendChild(pdfCombinerScript);
  }

  /// Merges multiple PDF files into a single PDF.
  ///
  /// This method sends a request to the native platform to merge the PDF files
  /// specified in the `paths` parameter and saves the result in the `outputPath`.
  ///
  /// Parameters:
  /// - `inputPaths`: A list of file paths of the PDFs to be merged.
  /// - `outputPath`: The directory path where the merged PDF should be saved.
  ///
  /// Returns:
  /// - A `Future<String?>` representing the result of the operation. If the operation
  ///   is successful, it returns a string message from the native platform; otherwise, it returns `null`.
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

  /// Creates a PDF from multiple image files.
  ///
  /// This method sends a request to the native platform to create a PDF from the
  /// images specified in the `inputPaths` parameter. The resulting PDF is saved in the
  /// `outputPath` directory.
  ///
  /// Parameters:
  /// - `inputPaths`: A list of file paths of the images to be converted into a PDF.
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
    required List<String> inputPaths,
    required String outputPath,
    PdfFromMultipleImageConfig config = const PdfFromMultipleImageConfig(),
  }) async {
    final JSArray<JSString> jsInputPaths = inputPaths.toJSArray();
    print("Entro dentro del createPDFFromMultipleImages y el valor del config desgranado es: width: ${config.rescale.width} y height: ${config.rescale.height} y keepAspectRatio: ${config.keepAspectRatio}");
    final JSString result =
        (await createPdfFromImages(jsInputPaths, config.jsify()).toDart)
            as JSString;
    print("JSSResult: $result");
    return result.toDart;
  }

  /// Creates images from a PDF file.
  ///
  /// This method sends a request to the native platform to extract images from the
  /// PDF file specified in the `path` parameter and saves the images in the `outputDirPath` directory.
  ///
  /// Parameters:
  /// - `inputPath`: The file path of the PDF from which images will be extracted.
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
    required String inputPath,
    required String outputPath,
    ImageFromPdfConfig config = const ImageFromPdfConfig(),
  }) async {
    final JSString jsInputPath = inputPath.toJS;
    final JSArray<JSString> result = config.createOneImage
        ? (await pdfToImage(jsInputPath, config.jsify()).toDart)
            as JSArray<JSString>
        : (await convertPdfToImages(jsInputPath, config.jsify()).toDart)
            as JSArray<JSString>;
    return result.toList();
  }
}
