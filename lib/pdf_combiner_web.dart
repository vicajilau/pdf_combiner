import 'dart:async';
import 'dart:js_interop';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:pdf_combiner/web/list_to_js_array_extension.dart';
import 'package:pdf_combiner/web/pdf_combiner_web_bindings.dart';
import 'package:web/web.dart';

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
    _loadJsScript();
    PdfCombinerPlatform.instance = PdfCombinerWeb();
  }

  static void _loadJsScript() {
    final base = document.createElement('base');
    final metacharset = document.createElement('meta');
    final metaIEEdge = document.createElement('meta');
    final metaDescription = document.createElement('meta');
    final metaMobileWebAppCapable = document.createElement('meta');
    final metaMobileAppStatusBar = document.createElement('meta');
    final metaMobileWebAppTitle = document.createElement('meta');
    final linkAppleTouchIcon = document.createElement('link');
    final linkicon = document.createElement('link');
    final pdfMinScript = document.createElement('script');
    final pdfWorkerScript = document.createElement('script');
    final pdfLibScript = document.createElement('script');
    final pdfCombinerScript = document.createElement('script');
    final linkManifest = document.createElement('link');
    final flutterBoot = document.createElement('script');

    base.setAttribute('href', "FLUTTER_BASE_HREF");
    metacharset.setAttribute('charset', 'UTF-8');
    metaIEEdge.setAttribute('content', 'IE=Edge');
    metaIEEdge.setAttribute('http-equiv', 'X-UA-Compatible');
    metaDescription.setAttribute('name', 'description');
    metaDescription.setAttribute('content', 'Demonstrates how to use the pdf_combiner plugin.');
    metaMobileWebAppCapable.setAttribute('name', 'mobile-web-app-capable');
    metaMobileWebAppCapable.setAttribute('content', 'yes');
    metaMobileAppStatusBar.setAttribute('name', 'mobile-web-app-status-bar-style');
    metaMobileAppStatusBar.setAttribute('content', 'black');
    metaMobileWebAppTitle.setAttribute('name', 'apple-mobile-web-app-title');
    metaMobileWebAppTitle.setAttribute('content', 'pdf_combiner_example');
    linkAppleTouchIcon.setAttribute('rel', 'apple-touch-icon');
    linkAppleTouchIcon.setAttribute('href', 'icons/Icon-192.png');
    linkicon.setAttribute('rel', 'icon');
    linkicon.setAttribute('type', 'image/png');
    linkicon.setAttribute('href', 'favicon.png');
    pdfMinScript.setAttribute('src', 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.min.js');
    pdfMinScript.setAttribute('type', 'text/javascript');
    pdfWorkerScript.setAttribute('src', 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.worker.min.js');
    pdfWorkerScript.setAttribute('type', 'text/javascript');
    pdfLibScript.setAttribute('src', 'https://cdnjs.cloudflare.com/ajax/libs/pdf-lib/1.17.1/pdf-lib.min.js');
    pdfLibScript.setAttribute('type', 'text/javascript');
    pdfCombinerScript.setAttribute('src', 'assets/packages/pdf_combiner/lib/web/assets/js/pdf_combiner.js');
    pdfCombinerScript.setAttribute('type', 'text/javascript');
    linkManifest.setAttribute('rel', 'manifest');
    linkManifest.setAttribute('href', 'manifest.json');
    flutterBoot.setAttribute('src', 'flutter_bootstrap.js');

    document.head!.appendChild(base);
    document.head!.appendChild(metacharset);
    document.head!.appendChild(metaIEEdge);
    document.head!.appendChild(metaDescription);
    document.head!.appendChild(metaMobileWebAppCapable);
    document.head!.appendChild(metaMobileAppStatusBar);
    document.head!.appendChild(metaMobileWebAppTitle);
    document.head!.appendChild(linkAppleTouchIcon);
    document.head!.appendChild(linkicon);
    document.head!.appendChild(pdfMinScript);
    document.head!.appendChild(pdfWorkerScript);
    document.head!.appendChild(pdfLibScript);
    document.head!.appendChild(pdfCombinerScript);
    document.head!.appendChild(linkManifest);
    document.body!.appendChild(flutterBoot);

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
