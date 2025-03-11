import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:pdf_combiner/isolates/images_from_pdf_isolate.dart';
import 'package:pdf_combiner/models/pdf_from_multiple_image_config.dart';
import 'package:pdf_combiner/responses/generate_pdf_from_documents_response.dart';
import 'package:pdf_combiner/responses/image_from_pdf_response.dart';
import 'package:pdf_combiner/responses/merge_multiple_pdf_response.dart';
import 'package:pdf_combiner/responses/pdf_combiner_messages.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';
import 'package:pdf_combiner/responses/pdf_from_multiple_image_response.dart';
import 'package:pdf_combiner/utils/document_utils.dart';

import 'isolates/merge_pdfs_isolate.dart';
import 'isolates/pdf_from_multiple_images_isolate.dart';
import 'models/image_from_pdf_config.dart';

/// The `PdfCombiner` class provides functionality for combining multiple PDF files.
///
/// It communicates with the platform-specific implementation of the PDF combiner using
/// the `PdfCombinerPlatform` interface. This class exposes a method to combine PDFs
/// and handles errors that may occur during the process.
class PdfCombiner {
  /// A boolean flag to indicate whether mocking is enabled.
  /// When set to true, isolates will not be executed, allowing tests to pass
  /// without performing actual PDF merging operations.
  static bool isMock = false;

  /// Combines multiple files into a single PDF. The input files can be either PDFs or images.
  ///
  /// This method takes a list of file paths (`inputPaths`) and an output file path (`outputPath`).
  /// It first verifies that the provided paths are valid and then processes the input files.
  /// - If an input file is an image, it is converted to a temporary PDF.
  /// - If an input file is a PDF, it remains unchanged.
  /// - If an input file is neither a PDF nor an image, the process stops with an error.
  ///
  /// The final result is a merged PDF that includes all the input files.
  ///
  /// ### Parameters:
  /// - [inputPaths] A list of file paths to be combined into a single PDF.
  /// - [outputPath] The path where the final merged PDF will be saved.
  ///
  /// ### Returns:
  /// - A [GeneratePdfFromDocumentsResponse] object containing the operation status and message.
  ///
  /// ### Errors:
  /// - Returns an error if `inputPaths` is empty.
  /// - Returns an error if `outputPath` is empty.
  /// - Returns an error if any input file is neither a PDF nor an image.
  /// - Returns an error if the image-to-PDF conversion fails.
  /// - Returns an error if the merging process fails.
  static Future<GeneratePdfFromDocumentsResponse> generatePDFFromDocuments({
    required List<String> inputPaths,
    required String outputPath,
  }) async {
    if (inputPaths.isEmpty) {
      return GeneratePdfFromDocumentsResponse(
        status: PdfCombinerStatus.error,
        message: PdfCombinerMessages.emptyParameterMessage("inputPaths"),
      );
    } else if (outputPath.trim().isEmpty) {
      return GeneratePdfFromDocumentsResponse(
        status: PdfCombinerStatus.error,
        message: PdfCombinerMessages.emptyParameterMessage("outputPath"),
      );
    } else {
      final List<String> mutablePaths = List.from(inputPaths);
      String dirname = path.dirname(outputPath);
      print("mi path es: $dirname");
      for (int i = 0; i < mutablePaths.length; i++) {
        final path = mutablePaths[i];
        final isPDF = await DocumentUtils.isPDF(path);
        final isImage = await DocumentUtils.isImage(path);
        if (!isPDF && !isImage) {
          return GeneratePdfFromDocumentsResponse(
            status: PdfCombinerStatus.error,
            message: PdfCombinerMessages.errorMessageMixed(path),
          );
        } else {
          if (isImage) {
            final response = await PdfCombiner.createPDFFromMultipleImages(
                inputPaths: [path], outputPath: "$dirname/document_$i.pdf");
            if (response.status == PdfCombinerStatus.success) {
              mutablePaths[i] = response.outputPath;
            } else {
              return GeneratePdfFromDocumentsResponse(
                status: PdfCombinerStatus.error,
                message:
                    response.message ?? "Error creating PDF from image: $path",
              );
            }
          }
        }
      }
      final response = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: mutablePaths,
        outputPath: outputPath,
      );
      if (response.status == PdfCombinerStatus.success) {
        return GeneratePdfFromDocumentsResponse(
          status: PdfCombinerStatus.success,
          message: PdfCombinerMessages.successMessage,
          outputPath: response.outputPath,
        );
      } else {
        return GeneratePdfFromDocumentsResponse(
          status: PdfCombinerStatus.error,
          message: response.message,
        );
      }
    }
  }

  /// Combines multiple PDF files into a single PDF.
  ///
  /// This method takes a list of file paths (`inputPaths`) representing the PDFs to be combined,
  /// and an `outputPath` where the resulting combined PDF should be saved.
  ///
  /// If the operation is successful, it returns the result from the platform-specific implementation.
  /// If an error occurs, it returns a message describing the error.
  ///
  /// Parameters:
  /// - `inputPaths`: A list of strings representing the paths of the PDF files to be combined.
  /// - `outputPath`: A string representing the directory where the combined PDF should be saved.
  ///
  /// Returns:
  /// - A `Future<MergeMultiplePDFResponse?>` representing the result of the operation (either the success message or an error message).
  static Future<MergeMultiplePDFResponse> mergeMultiplePDFs(
      {required List<String> inputPaths, required String outputPath}) async {
    if (inputPaths.isEmpty) {
      return MergeMultiplePDFResponse(
          status: PdfCombinerStatus.error,
          message: PdfCombinerMessages.emptyParameterMessage("inputPaths"));
    } else {
      try {
        bool success = true;
        String path = "";
        int i = 0;

        while (i < inputPaths.length && success) {
          success = await DocumentUtils.isPDF(inputPaths[i]);
          path = inputPaths[i];
          i++;
        }

        if (!success) {
          return MergeMultiplePDFResponse(
              status: PdfCombinerStatus.error,
              message: PdfCombinerMessages.errorMessagePDF(path));
        } else {
          final String? response = await MergePdfsIsolate.mergeMultiplePDFs(
              inputPaths: inputPaths, outputPath: outputPath);

          if (response != null &&
              (response == outputPath || response.startsWith("blob:http"))) {
            return MergeMultiplePDFResponse(
                status: PdfCombinerStatus.success,
                message: PdfCombinerMessages.successMessage,
                outputPath: response);
          } else {
            return MergeMultiplePDFResponse(
                status: PdfCombinerStatus.error,
                message: response ?? PdfCombinerMessages.errorMessage);
          }
        }
      } catch (e) {
        return MergeMultiplePDFResponse(
            status: PdfCombinerStatus.error, message: e.toString());
      }
    }
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
  /// - A `Future<PdfFromMultipleImageResponse?>` representing the result of the operation (either the success message or an error message).
  static Future<PdfFromMultipleImageResponse> createPDFFromMultipleImages({
    required List<String> inputPaths,
    required String outputPath,
    PdfFromMultipleImageConfig config = const PdfFromMultipleImageConfig(),
  }) async {
    if (inputPaths.isEmpty) {
      return PdfFromMultipleImageResponse(
        status: PdfCombinerStatus.error,
        message: PdfCombinerMessages.emptyParameterMessage("inputPaths"),
      );
    } else {
      try {
        bool success = true;
        String path = "";
        int i = 0;

        while (i < inputPaths.length && success) {
          success = await DocumentUtils.isImage(inputPaths[i]);
          path = inputPaths[i];
          i++;
        }

        if (!success) {
          return PdfFromMultipleImageResponse(
            status: PdfCombinerStatus.error,
            message: PdfCombinerMessages.errorMessageImage(path),
          );
        } else {
          final String? response =
              await PdfFromMultipleImagesIsolate.createPDFFromMultipleImages(
            inputPaths: inputPaths,
            outputPath: outputPath,
            config: config,
          );

          if (response != null &&
              (response == outputPath || response.startsWith("blob:http"))) {
            return PdfFromMultipleImageResponse(
              status: PdfCombinerStatus.success,
              message: PdfCombinerMessages.successMessage,
              outputPath: response,
            );
          } else {
            return PdfFromMultipleImageResponse(
              status: PdfCombinerStatus.error,
              message: response ?? PdfCombinerMessages.errorMessage,
            );
          }
        }
      } catch (e) {
        return PdfFromMultipleImageResponse(
          status: PdfCombinerStatus.error,
          message: e.toString(),
        );
      }
    }
  }

  /// For Creating a Image from PDF
  /// paths selected file path (String). Example user/android.downlaod/MYPDF.pdf
  /// outputPath is output path with filename, example /user/android/download/ABC.pdf
  /// Optional params maxWidth : default set to 360, maxHeight : default set to 360, createOneImage : default set to true.
  ///
  /// Create a list of images from a PDF.
  ///
  /// This method takes a single pdf file path (`inputPath`) representing the pdf file to be extracted,
  /// and an `outputPath` with folder where the resulting list of images should be saved.
  ///
  /// If the operation is successful, it returns the result from the platform-specific implementation.
  /// If an error occurs, it returns a message describing the error.
  ///
  /// Parameters:
  /// - `inputPath`: A string representing the pdf document file path to be extracted.
  /// - `outputDirPath`: A string representing the directory where the list of images should be saved.
  /// - `config`: A configuration object that specifies how to process the images.
  ///   - `rescale`: The scaling configuration for the images (default is the original image).
  ///   - `compression`: The image compression level for the images, affecting file size, quality and clarity (default is [ImageCompression.none]).
  ///   - `createOneImage`: Indicates whether to create a single image or separate images for each page (default is `true`).
  ///
  /// Returns:
  /// - A `Future<ImageFromPDFResponse?>` representing the result of the operation (either the success message or an error message).
  static Future<ImageFromPDFResponse> createImageFromPDF(
      {required String inputPath,
      required String outputDirPath,
      ImageFromPdfConfig config = const ImageFromPdfConfig()}) async {
    if (inputPath.trim().isEmpty) {
      return ImageFromPDFResponse(
          status: PdfCombinerStatus.error,
          message: PdfCombinerMessages.emptyParameterMessage("inputPath"));
    } else {
      try {
        bool success = await DocumentUtils.isPDF(inputPath);

        if (!success) {
          return ImageFromPDFResponse(
            status: PdfCombinerStatus.error,
            message: PdfCombinerMessages.errorMessagePDF(inputPath),
          );
        } else {
          final response = await ImagesFromPdfIsolate.createImageFromPDF(
              inputPath: inputPath,
              outputDirectory: outputDirPath,
              config: config);

          if (response != null && response.isNotEmpty) {
            if (response.first.contains(outputDirPath) ||
                response.first.startsWith("blob:http")) {
              return ImageFromPDFResponse(
                status: PdfCombinerStatus.success,
                outputPaths: response,
              );
            } else {
              return ImageFromPDFResponse(
                status: PdfCombinerStatus.error,
                message: response.first,
              );
            }
          } else {
            return ImageFromPDFResponse(
              status: PdfCombinerStatus.error,
              message: PdfCombinerMessages.errorMessage,
            );
          }
        }
      } catch (e) {
        return ImageFromPDFResponse(
            status: PdfCombinerStatus.error, message: e.toString());
      }
    }
  }
}
