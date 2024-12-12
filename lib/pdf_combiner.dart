import 'package:get/get_utils/src/get_utils/get_utils.dart';
import 'package:pdf_combiner/responses/image_from_pdf_response.dart';
import 'package:pdf_combiner/responses/merge_multiple_pdf_response.dart';
import 'package:pdf_combiner/responses/pdf_from_multiple_image_response.dart';

import 'communication/pdf_combiner_platform_interface.dart';
import 'communication/status.dart';

/// The `PdfCombiner` class provides functionality for combining multiple PDF files.
///
/// It communicates with the platform-specific implementation of the PDF combiner using
/// the `PdfCombinerPlatform` interface. This class exposes a method to combine PDFs
/// and handles errors that may occur during the process.
class PdfCombiner {
  /// Combines multiple PDF files into a single PDF.
  ///
  /// This method takes a list of file paths (`filePaths`) representing the PDFs to be combined,
  /// and an `outputPath` where the resulting combined PDF should be saved.
  ///
  /// If the operation is successful, it returns the result from the platform-specific implementation.
  /// If an error occurs, it returns a message describing the error.
  ///
  /// Parameters:
  /// - `filePaths`: A list of strings representing the paths of the PDF files to be combined.
  /// - `outputPath`: A string representing the directory where the combined PDF should be saved.
  ///
  /// Returns:
  /// - A `Future<String?>` representing the result of the operation (either the success message or an error message).
  static Future<MergeMultiplePDFResponse> mergeMultiplePDF(
      {required List<String> filePaths, required String outputPath}) async {
    MergeMultiplePDFResponse mergeMultiplePDFResponse =
        MergeMultiplePDFResponse();
    if (filePaths.isEmpty) {
      mergeMultiplePDFResponse.status = Status.error;
      mergeMultiplePDFResponse.message = Status.errorMessage;
    } else {
      try {
        bool isPDF = true;

        for (int i = 0; i < filePaths.length; i++) {
          if (!GetUtils.isPDF(filePaths[i])) {
            isPDF = false;
          }
        }

        if (!isPDF) {
          mergeMultiplePDFResponse.status = Status.error;
          mergeMultiplePDFResponse.message = Status.errorMessagePDF;
        } else {
          final String? response = await PdfCombinerPlatform.instance
              .mergeMultiplePDF(paths: filePaths, outputDirPath: outputPath);

          if (response != "error") {
            mergeMultiplePDFResponse.status = Status.success;
            mergeMultiplePDFResponse.message = Status.successMessage;
            mergeMultiplePDFResponse.response = response;
          } else {
            mergeMultiplePDFResponse.status = Status.error;
            mergeMultiplePDFResponse.message = Status.errorMessage;
          }
        }
      } on Exception catch (exception) {
        mergeMultiplePDFResponse.status = Status.error;
        mergeMultiplePDFResponse.message = exception.toString();
      } catch (e) {
        mergeMultiplePDFResponse.status = Status.error;
        mergeMultiplePDFResponse.message = e.toString();
      }
    }

    return mergeMultiplePDFResponse;
  }

  /// For Creating a PDF from multiple image
  /// paths is a list of paths, example List<String> allSelectedFilePath.
  /// outputDirPath is output path with filename, example /user/android/download/ABC.pdf
  /// Optional params maxWidth : default set to 360, maxHeight : default set to 360, needImageCompressor : default set to true.
  static Future<PdfFromMultipleImageResponse> createPDFFromMultipleImage(
      {required List<String> paths,
      required String outputDirPath,
      int maxWidth = 360,
      int maxHeight = 360,
      bool needImageCompressor = true}) async {
    PdfFromMultipleImageResponse createPDFFromMultipleImageResponse =
        PdfFromMultipleImageResponse();
    if (paths.isEmpty) {
      createPDFFromMultipleImageResponse.status = Status.error;
      createPDFFromMultipleImageResponse.message = Status.errorMessage;
    } else {
      try {
        bool isImage = true;

        for (int i = 0; i < paths.length; i++) {
          if (!GetUtils.isImage(paths[i])) {
            isImage = false;
          }
        }

        if (!isImage) {
          createPDFFromMultipleImageResponse.status = Status.error;
          createPDFFromMultipleImageResponse.message = Status.errorMessageImage;
        } else {
          final String? response = await PdfCombinerPlatform.instance
              .createPDFFromMultipleImage(
                  paths: paths,
                  outputDirPath: outputDirPath,
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                  needImageCompressor: needImageCompressor);

          if (response != "error") {
            createPDFFromMultipleImageResponse.status = Status.success;
            createPDFFromMultipleImageResponse.message = Status.successMessage;
            createPDFFromMultipleImageResponse.response = response;
          } else {
            createPDFFromMultipleImageResponse.status = Status.error;
            createPDFFromMultipleImageResponse.message = Status.errorMessage;
          }
        }
      } on Exception catch (exception) {
        createPDFFromMultipleImageResponse.status = Status.error;
        createPDFFromMultipleImageResponse.message = exception.toString();
      } catch (e) {
        createPDFFromMultipleImageResponse.status = Status.error;
        createPDFFromMultipleImageResponse.message = e.toString();
      }
    }

    return createPDFFromMultipleImageResponse;
  }

  /// For Creating a Image from PDF
  /// paths selected file path (String). Example user/android.downlaod/MYPDF.pdf
  /// outputDirPath is output path with filename, example /user/android/download/ABC.pdf
  /// Optional params maxWidth : default set to 360, maxHeight : default set to 360, createOneImage : default set to true.
  static Future<ImageFromPDFResponse> createImageFromPDF(
      {required String path,
      required String outputDirPath,
      int maxWidth = 360,
      int maxHeight = 360,
      bool createOneImage = true}) async {
    ImageFromPDFResponse createImageFromPDFResponse = ImageFromPDFResponse();

    if (path == "") {
      createImageFromPDFResponse.status = Status.error;
      createImageFromPDFResponse.message = Status.errorMessage;
    } else {
      try {
        bool isImage = GetUtils.isPDF(path);

        if (!isImage) {
          createImageFromPDFResponse.status = Status.error;
          createImageFromPDFResponse.message = Status.errorMessageImage;
        } else {
          final response = await PdfCombinerPlatform.instance
              .createImageFromPDF(
                  path: path,
                  outputDirPath: outputDirPath,
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                  createOneImage: createOneImage);

          if (response != null && response.isNotEmpty) {
            createImageFromPDFResponse.response = [];
            for (int i = 0; i < response.length; i++) {
              createImageFromPDFResponse.response!.add(response[i]);
            }

            createImageFromPDFResponse.status = Status.success;
            createImageFromPDFResponse.message = Status.successMessage;
          } else {
            createImageFromPDFResponse.status = Status.error;
            createImageFromPDFResponse.message = Status.errorMessage;
          }
        }
      } on Exception catch (exception) {
        createImageFromPDFResponse.status = Status.error;
        createImageFromPDFResponse.message = exception.toString();
      } catch (e) {
        createImageFromPDFResponse.status = Status.error;
        createImageFromPDFResponse.message = e.toString();
      }
    }

    return createImageFromPDFResponse;
  }
}
