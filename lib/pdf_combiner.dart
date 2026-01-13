import 'dart:async';

import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/isolates/images_from_pdf_isolate.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf_combiner/models/pdf_from_multiple_image_config.dart';
import 'package:pdf_combiner/responses/pdf_combiner_messages.dart';
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
  /// - A [String] object containing the output path.
  ///
  /// ### Errors:
  /// - Returns an error if `inputPaths` is empty.
  /// - Returns an error if `outputPath` is empty.
  /// - Returns an error if any input file is neither a PDF nor an image.
  /// - Returns an error if the image-to-PDF conversion fails.
  /// - Returns an error if the merging process fails.
  static Future<String> generatePDFFromDocuments({
    required List<String> inputPaths,
    required String outputPath,
  }) async {
    if (inputPaths.isEmpty) {
      throw (PdfCombinerException(
          PdfCombinerMessages.emptyParameterMessage("inputPaths")));
    } else if (outputPath.trim().isEmpty) {
      throw (PdfCombinerException(
          PdfCombinerMessages.emptyParameterMessage("outputPath")));
    } else {
      final List<String> mutablePaths = List.from(inputPaths);
      for (int i = 0; i < mutablePaths.length; i++) {
        var path = mutablePaths[i];
        final isPDF = await DocumentUtils.isPDF(path);
        final isImage = await DocumentUtils.isImage(path);
        final outputPathIsPDF = DocumentUtils.hasPDFExtension(outputPath);
        if (!outputPathIsPDF) {
          throw (PdfCombinerException(
              PdfCombinerMessages.errorMessageInvalidOutputPath(outputPath)));
        } else if (!isPDF && !isImage) {
          throw (PdfCombinerException(
              PdfCombinerMessages.errorMessageMixed(path)));
        } else {
          if (isImage) {
            if (await DocumentUtils.isHeicImage(path)) {
              path = await DocumentUtils.convertHeicToJpeg(path) ?? path;
            }
            final temporalOutputPath = kIsWeb
                ? "document_$i.pdf"
                : "${DocumentUtils.getTemporalFolderPath()}/document_$i.pdf";
            final response = await PdfCombiner.createPDFFromMultipleImages(
              inputPaths: [path],
              outputPath: temporalOutputPath,
            );

            mutablePaths[i] = response;
          }
        }
      }
      final response = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: mutablePaths,
        outputPath: outputPath,
      );
      DocumentUtils.removeTemporalFiles(mutablePaths);

      return response;
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
  /// - A `Future<String>` representing the result of the operation (either the success message or an error message).
  static Future<String> mergeMultiplePDFs({
    required List<String> inputPaths,
    required String outputPath,
  }) async {
    if (inputPaths.isEmpty) {
      throw PdfCombinerException(
          PdfCombinerMessages.emptyParameterMessage("inputPaths"));
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

        final outputPathIsPDF = DocumentUtils.hasPDFExtension(outputPath);
        if (!outputPathIsPDF) {
          throw PdfCombinerException(
              PdfCombinerMessages.errorMessageInvalidOutputPath(outputPath));
        } else if (!success) {
          throw PdfCombinerException(PdfCombinerMessages.errorMessagePDF(path));
        } else {
          final String? response = await MergePdfsIsolate.mergeMultiplePDFs(
              inputPaths: inputPaths, outputPath: outputPath);

          if (response != null &&
              (response == outputPath || response.startsWith("blob:http"))) {
            return response;
          }

          final exception = PdfCombinerException(
              response ?? PdfCombinerMessages.errorMessage);
          throw exception;
        }
      } catch (e) {
        throw e is Exception ? e : PdfCombinerException(e.toString());
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
  /// - A `Future<String>` representing the result of the operation (either the success message or an error message).
  static Future<String> createPDFFromMultipleImages({
    required List<String> inputPaths,
    required String outputPath,
    PdfFromMultipleImageConfig config = const PdfFromMultipleImageConfig(),
  }) async {
    final outputPathIsPDF = DocumentUtils.hasPDFExtension(outputPath);
    if (!outputPathIsPDF) {
      throw PdfCombinerException(
          PdfCombinerMessages.errorMessageInvalidOutputPath(outputPath));
    } else if (inputPaths.isEmpty) {
      throw PdfCombinerException(
          PdfCombinerMessages.emptyParameterMessage("inputPaths"));
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
          throw PdfCombinerException(
              PdfCombinerMessages.errorMessageImage(path));
        } else {
          final String? response =
              await PdfFromMultipleImagesIsolate.createPDFFromMultipleImages(
            inputPaths: inputPaths,
            outputPath: outputPath,
            config: config,
          );
          if (response != null &&
              (response == outputPath || response.startsWith("blob:http"))) {
            return response;
          } else {
            throw PdfCombinerException(
                response ?? PdfCombinerMessages.errorMessage);
          }
        }
      } catch (e) {
        throw e is Exception ? e : PdfCombinerException(e.toString());
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
  /// - A `Future<List<String>>` representing the result of the operation (either the success message or an error message).
  static Future<List<String>> createImageFromPDF({
    required String inputPath,
    required String outputDirPath,
    ImageFromPdfConfig config = const ImageFromPdfConfig(),
  }) async {
    if (inputPath.trim().isEmpty) {
      throw PdfCombinerException(
          PdfCombinerMessages.emptyParameterMessage("inputPath"));
    } else {
      try {
        bool success = await DocumentUtils.isPDF(inputPath);

        if (!success) {
          throw PdfCombinerException(
              PdfCombinerMessages.errorMessagePDF(inputPath));
        } else {
          final response = await ImagesFromPdfIsolate.createImageFromPDF(
              inputPath: inputPath,
              outputDirectory: outputDirPath,
              config: config);

          if (response != null && response.isNotEmpty) {
            if (response.first.contains(outputDirPath) ||
                response.first.startsWith("blob:http")) {
              return response;
            } else {
              throw PdfCombinerException(response.first);
            }
          } else {
            throw PdfCombinerException(PdfCombinerMessages.errorMessage);
          }
        }
      } catch (e) {
        throw e is Exception ? e : PdfCombinerException(e.toString());
      }
    }
  }
}
