import 'dart:async';

import 'package:pdf_combiner/models/pdf_from_multiple_image_config.dart';
import 'package:pdf_combiner/responses/image_from_pdf_response.dart';
import 'package:pdf_combiner/responses/merge_multiple_pdf_response.dart';
import 'package:pdf_combiner/responses/pdf_combiner_messages.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';
import 'package:pdf_combiner/responses/pdf_from_multiple_image_response.dart';
import 'package:pdf_combiner/utils/document_utils.dart';

import 'communication/pdf_combiner_platform_interface.dart';
import 'models/image_from_pdf_config.dart';

/// The `PdfCombiner` class provides functionality for combining multiple PDF files.
///
/// It communicates with the platform-specific implementation of the PDF combiner using
/// the `PdfCombinerPlatform` interface. This class exposes a method to combine PDFs
/// and handles errors that may occur during the process.
class PdfCombiner {
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
          final String? response = await PdfCombinerPlatform.instance
              .mergeMultiplePDFs(
                  inputPaths: inputPaths, outputPath: outputPath);

          if (response != null && response != "error") {
            return MergeMultiplePDFResponse(
                status: PdfCombinerStatus.success,
                message: PdfCombinerMessages.successMessage,
                outputPath: response);
          } else {
            return MergeMultiplePDFResponse(
                status: PdfCombinerStatus.error,
                message: PdfCombinerMessages.errorMessage);
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
  ///   - `compression`: The image quality level for compression, affecting file size and clarity (default is [ImageQuality.high]).
  ///   - `keepAspectRatio`: Indicates whether to maintain the aspect ratio of the images (default is `true`).
  ///
  /// Returns:
  /// - A `Future<PdfFromMultipleImageResponse?>` representing the result of the operation (either the success message or an error message).
  static Future<PdfFromMultipleImageResponse> createPDFFromMultipleImages({
    required List<String> inputPaths,
    required String outputPath,
    PdfFromMultipleImageConfig config = const PdfFromMultipleImageConfig(),
  }) async {
    PdfFromMultipleImageResponse createPDFFromMultipleImageResponse =
        PdfFromMultipleImageResponse();
    if (inputPaths.isEmpty) {
      createPDFFromMultipleImageResponse.status = PdfCombinerStatus.error;
      createPDFFromMultipleImageResponse.message =
          PdfCombinerMessages.emptyParameterMessage("inputPaths");
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
          createPDFFromMultipleImageResponse.status = PdfCombinerStatus.error;
          createPDFFromMultipleImageResponse.message =
              PdfCombinerMessages.errorMessageImage(path);
          createPDFFromMultipleImageResponse.response = null;
        } else {
          final String? response =
              await PdfCombinerPlatform.instance.createPDFFromMultipleImages(
            inputPaths: inputPaths,
            outputPath: outputPath,
            config: config,
          );

          if (response != "error") {
            createPDFFromMultipleImageResponse.status =
                PdfCombinerStatus.success;
            createPDFFromMultipleImageResponse.message =
                PdfCombinerMessages.successMessage;
            createPDFFromMultipleImageResponse.response = response;
          } else {
            createPDFFromMultipleImageResponse.status = PdfCombinerStatus.error;
            createPDFFromMultipleImageResponse.message =
                PdfCombinerMessages.errorMessage;
          }
        }
      } catch (e) {
        createPDFFromMultipleImageResponse.status = PdfCombinerStatus.error;
        createPDFFromMultipleImageResponse.message = e.toString();
      }
    }

    return createPDFFromMultipleImageResponse;
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
  /// - `outputPath`: A string representing the directory where the list of images should be saved.
  /// - `config`: A configuration object that specifies how to process the images.
  ///   - `rescale`: The scaling configuration for the images (default is the original image).
  ///   - `compression`: The image quality level for compression, affecting file size and clarity (default is [ImageQuality.high]).
  ///   - `createOneImage`: Indicates whether to create a single image or separate images for each page (default is `true`).
  ///
  /// Returns:
  /// - A `Future<ImageFromPDFResponse?>` representing the result of the operation (either the success message or an error message).
  static Future<ImageFromPDFResponse> createImageFromPDF(
      {required String inputPath,
      required String outputPath,
      ImageFromPdfConfig config = const ImageFromPdfConfig()}) async {
    ImageFromPDFResponse createImageFromPDFResponse = ImageFromPDFResponse();

    if (inputPath.trim().isEmpty) {
      createImageFromPDFResponse.status = PdfCombinerStatus.error;
      createImageFromPDFResponse.message =
          PdfCombinerMessages.emptyParameterMessage("inputPath");
    } else {
      try {
        bool success = await DocumentUtils.isPDF(inputPath);

        if (!success) {
          createImageFromPDFResponse.status = PdfCombinerStatus.error;
          createImageFromPDFResponse.message =
              PdfCombinerMessages.errorMessagePDF(inputPath);
        } else {
          final response =
              await PdfCombinerPlatform.instance.createImageFromPDF(
            inputPath: inputPath,
            outputPath: outputPath,
            config: config,
          );

          if (response != null && response.isNotEmpty) {
            createImageFromPDFResponse.response = [];
            for (var file in response) {
              createImageFromPDFResponse.response!.add(file);
            }
          }

          createImageFromPDFResponse.status = PdfCombinerStatus.success;
          createImageFromPDFResponse.message =
              PdfCombinerMessages.successMessage;
        }
      } catch (e) {
        createImageFromPDFResponse.status = PdfCombinerStatus.error;
        createImageFromPDFResponse.message = e.toString();
      }
    }

    return createImageFromPDFResponse;
  }
}
