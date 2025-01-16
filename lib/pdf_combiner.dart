import 'package:flutter/foundation.dart';
import 'package:pdf_combiner/document_utils.dart';
import 'package:pdf_combiner/responses/image_from_pdf_response.dart';
import 'package:pdf_combiner/responses/merge_multiple_pdf_response.dart';
import 'package:pdf_combiner/responses/pdf_combiner_messages.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';
import 'package:pdf_combiner/responses/pdf_from_multiple_image_response.dart';

import 'communication/pdf_combiner_platform_interface.dart';

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
  /// - A `Future<String?>` representing the result of the operation (either the success message or an error message).
  static Future<MergeMultiplePDFResponse> mergeMultiplePDFs(
      {required List<String> inputPaths, required String outputPath}) async {
    MergeMultiplePDFResponse mergeMultiplePDFResponse =
        MergeMultiplePDFResponse();
    if (inputPaths.isEmpty) {
      mergeMultiplePDFResponse.status = PdfCombinerStatus.error;
      mergeMultiplePDFResponse.message =
          PdfCombinerMessages.emptyParameterMessage("inputPaths");
    } else {
      try {
        bool isPDF = true;
        bool existFile = true;
        String path = "";

        for (int i = 0; i < inputPaths.length; i++) {

            isPDF = DocumentUtils.isPDF(inputPaths[i]);
            path = inputPaths[i];

          if(DocumentUtils.fileExist(inputPaths[i])){
            existFile = true;
            path = inputPaths[i];
          }else  {
            existFile = false;
            path = inputPaths[i];
          }
        }

        if (!isPDF) {
          mergeMultiplePDFResponse.status = PdfCombinerStatus.error;
          mergeMultiplePDFResponse.message =
              PdfCombinerMessages.errorMessagePDF(path);
        } else if (!existFile) {
          mergeMultiplePDFResponse.status = PdfCombinerStatus.error;
          mergeMultiplePDFResponse.message =
              PdfCombinerMessages.errorMessageFile(path);
        } else {
          final String? response = await PdfCombinerPlatform.instance
              .mergeMultiplePDFs(
                  inputPaths: inputPaths, outputPath: outputPath);

          if (response != "error") {
            mergeMultiplePDFResponse.status = PdfCombinerStatus.success;
            mergeMultiplePDFResponse.message =
                PdfCombinerMessages.successMessage;
            mergeMultiplePDFResponse.response = response;
          } else {
            mergeMultiplePDFResponse.status = PdfCombinerStatus.error;
            mergeMultiplePDFResponse.message = PdfCombinerMessages.errorMessage;
          }
        }
      } on Exception catch (exception) {
        mergeMultiplePDFResponse.status = PdfCombinerStatus.error;
        mergeMultiplePDFResponse.message = exception.toString();
      } catch (e) {
        mergeMultiplePDFResponse.status = PdfCombinerStatus.error;
        mergeMultiplePDFResponse.message = e.toString();
      }
    }

    return mergeMultiplePDFResponse;
  }

  /// For Creating a PDF from multiple image
  /// paths is a list of paths, example List&gt;String&gt; allSelectedFilePath.
  /// outputPath is output path with filename, example /user/android/download/ABC.pdf
  /// Optional params maxWidth : default set to 360, maxHeight : default set to 360, needImageCompressor : default set to true.
  static Future<PdfFromMultipleImageResponse> createPDFFromMultipleImages(
      {required List<String> inputPaths,
      required String outputPath,
      int maxWidth = 360,
      int maxHeight = 360,
      bool needImageCompressor = true}) async {
    PdfFromMultipleImageResponse createPDFFromMultipleImageResponse =
        PdfFromMultipleImageResponse();
    if (inputPaths.isEmpty) {
      createPDFFromMultipleImageResponse.status = PdfCombinerStatus.error;
      createPDFFromMultipleImageResponse.message =
          PdfCombinerMessages.emptyParameterMessage("inputPaths");
    } else {
      try {
        bool isImage = true;
        bool existFile = true;
        String path = "";

        for (int i = 0; i < inputPaths.length; i++) {
          if (!DocumentUtils.isImage(inputPaths[i])) {
            isImage = false;
            path = inputPaths[i];
          }
          if (!DocumentUtils.fileExist(inputPaths[i])) {
            existFile = false;
            path = inputPaths[i];
          }
        }

        if (!isImage) {
          createPDFFromMultipleImageResponse.status = PdfCombinerStatus.error;
          createPDFFromMultipleImageResponse.message =
              PdfCombinerMessages.errorMessageImage(path);
        } else if (!existFile) {
          createPDFFromMultipleImageResponse.status = PdfCombinerStatus.error;
          createPDFFromMultipleImageResponse.message =
              PdfCombinerMessages.errorMessageFile(path);
        } else {
          final String? response = await PdfCombinerPlatform.instance
              .createPDFFromMultipleImages(
                  inputPaths: inputPaths,
                  outputPath: outputPath,
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                  needImageCompressor: needImageCompressor);

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
      } on Exception catch (exception) {
        createPDFFromMultipleImageResponse.status = PdfCombinerStatus.error;
        createPDFFromMultipleImageResponse.message = exception.toString();
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
  static Future<ImageFromPDFResponse> createImageFromPDF(
      {required String inputPath,
      required String outputPath,
      int maxWidth = 360,
      int maxHeight = 360,
      bool createOneImage = true}) async {
    ImageFromPDFResponse createImageFromPDFResponse = ImageFromPDFResponse();

    if (inputPath.trim().isEmpty) {
      createImageFromPDFResponse.status = PdfCombinerStatus.error;
      createImageFromPDFResponse.message =
          PdfCombinerMessages.emptyParameterMessage("inputPaths");
    } else {
      try {
        bool isImage = DocumentUtils.isPDF(inputPath);
        bool existFile = DocumentUtils.fileExist(inputPath);

        if (!isImage) {
          createImageFromPDFResponse.status = PdfCombinerStatus.error;
          createImageFromPDFResponse.message =
              PdfCombinerMessages.errorMessageImage(inputPath);
        } else if (!existFile) {
          createImageFromPDFResponse.status = PdfCombinerStatus.error;
          createImageFromPDFResponse.message =
              PdfCombinerMessages.errorMessageFile(inputPath);
        } else {
          final response = await PdfCombinerPlatform.instance
              .createImageFromPDF(
                  inputPath: inputPath,
                  outputPath: outputPath,
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                  createOneImage: createOneImage);

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
      } on Exception catch (exception) {
        createImageFromPDFResponse.status = PdfCombinerStatus.error;
        createImageFromPDFResponse.message = exception.toString();
      } catch (e) {
        createImageFromPDFResponse.status = PdfCombinerStatus.error;
        createImageFromPDFResponse.message = e.toString();
      }

    }

    return createImageFromPDFResponse;
  }

}
