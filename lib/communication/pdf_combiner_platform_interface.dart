import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../models/pdf_from_multiple_image_config.dart';
import 'pdf_combiner_method_channel.dart';

/// Abstract class that serves as the platform interface for PdfCombiner.
///
/// This class defines the methods that should be implemented by platform-specific
/// code to interact with the native code for PDF-related operations, such as merging
/// PDFs, creating PDFs from images, extracting images from PDFs, retrieving file sizes,
/// and fetching build information.
abstract class PdfCombinerPlatform extends PlatformInterface {
  /// Constructs a PdfCombinerPlatform.
  PdfCombinerPlatform() : super(token: _token);

  static final Object _token = Object();

  static PdfCombinerPlatform _instance = MethodChannelPdfCombiner();

  /// The default instance of [PdfCombinerPlatform] to use.
  ///
  /// This getter returns the default platform implementation (usually [MethodChannelPdfCombiner]).
  /// Platform-specific implementations should set this to their own class that extends [PdfCombinerPlatform].
  static PdfCombinerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PdfCombinerPlatform] when
  /// they register themselves.
  static set instance(PdfCombinerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Combines multiple PDFs into a single PDF.
  ///
  /// Platform-specific implementations should override this method to merge
  /// multiple PDFs and return the result.
  ///
  /// Parameters:
  /// - `inputs`: A list of [MergeInput] objects representing the PDFs to be merged.
  /// - `outputPath`: The directory path where the merged PDF should be saved.
  ///
  /// Returns:
  /// - A `Future<String?>` representing the result of the operation. By default,
  ///   this throws an [UnimplementedError].
  Future<String?> mergeMultiplePDFs({
    required List<MergeInput> inputs,
    required String outputPath,
  }) {
    throw UnimplementedError('mergeMultiplePDF() has not been implemented.');
  }

  /// Creates a PDF from multiple image files.
  ///
  /// This method sends a request to the native platform to create a PDF from the
  /// images specified in the `inputs` parameter. The resulting PDF is saved in the
  /// `outputPath` directory.
  ///
  /// Parameters:
  /// - `inputs`: A list of [MergeInput] objects representing the images to be converted into a PDF.
  /// - `outputPath`: The directory path where the created PDF should be saved.
  /// - `config`: A configuration object that specifies how to process the images.
  ///   - `rescale`: The scaling configuration for the images (default is the original image).
  ///   - `keepAspectRatio`: Indicates whether to maintain the aspect ratio of the images (default is `true`).
  ///
  /// Returns:
  /// - A `Future<String?>` representing the result of the operation. By default,
  ///   this throws an [UnimplementedError].
  Future<String?> createPDFFromMultipleImages({
    required List<MergeInput> inputs,
    required String outputPath,
    PdfFromMultipleImageConfig config = const PdfFromMultipleImageConfig(),
  }) {
    throw UnimplementedError(
        'createPDFFromMultipleImage() has not been implemented.');
  }

  /// Creates images from a PDF file.
  ///
  /// Platform-specific implementations should override this method to extract images
  /// from the provided PDF and return the resulting image file paths.
  ///
  /// Parameters:
  /// - `input`: The [MergeInput] object representing the PDF from which images will be extracted.
  /// - `outputPath`: The directory path where the images should be saved.
  /// - `config`: A configuration object that specifies how to process the images.
  ///   - `rescale`: The scaling configuration for the images (default is the original image).
  ///   - `compression`: The image compression level for the images, affecting file size, quality and clarity (default is [ImageCompression.none]).
  ///   - `createOneImage`: Indicates whether to create a single image or separate images for each page (default is `true`).
  ///
  /// Returns:
  /// - A `Future<List<String>?>` representing a list of image file paths. By default,
  ///   this throws an [UnimplementedError].
  Future<List<String>?> createImageFromPDF({
    required MergeInput input,
    required String outputPath,
    ImageFromPdfConfig config = const ImageFromPdfConfig(),
  }) {
    throw UnimplementedError('createImageFromPDF() has not been implemented.');
  }
}
