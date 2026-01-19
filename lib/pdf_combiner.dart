import 'dart:async';

import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/isolates/images_from_pdf_isolate.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf_combiner/responses/pdf_combiner_messages.dart';
import 'package:pdf_combiner/utils/document_utils.dart';
import 'package:pdf_combiner/isolates/merge_pdfs_isolate.dart';
import 'package:pdf_combiner/isolates/pdf_from_multiple_images_isolate.dart';

import 'models/image_from_pdf_config.dart';
import 'models/pdf_from_multiple_image_config.dart';
import 'models/merge_input.dart';
import 'dart:typed_data' show Uint8List;

export 'models/merge_input.dart';

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
  /// This method takes a list of [MergeInput] inputs which can be created from
  /// file paths, raw bytes ([Uint8List]), or [File] objects.
  /// It first verifies that the provided inputs are valid and then processes them.
  /// - If an input is an image, it is converted to a temporary PDF.
  /// - If an input is a PDF, it remains unchanged.
  /// - If an input is neither a PDF nor an image, the process stops with an error.
  ///
  /// The final result is a merged PDF that includes all the input files.
  ///
  /// ### Parameters:
  /// - [inputs] A list of [MergeInput] representing the files or bytes to be combined into a single PDF.
  /// - [outputPath] The path where the final merged PDF will be saved.
  ///
  /// ### Returns:
  /// - A [String] object containing the output path.
  ///
  /// ### Errors:
  /// - Returns an error if `inputs` is empty.
  /// - Returns an error if `outputPath` is empty.
  /// - Returns an error if any input is neither a PDF nor an image.
  /// - Returns an error if the image-to-PDF conversion fails.
  /// - Returns an error if the merging process fails.
  static Future<String> generatePDFFromDocuments({
    required List<MergeInput> inputs,
    required String outputPath,
  }) async {
    if (inputs.isEmpty) {
      throw (PdfCombinerException(
          PdfCombinerMessages.emptyParameterMessage("inputs")));
    } else if (outputPath.trim().isEmpty) {
      throw (PdfCombinerException(
          PdfCombinerMessages.emptyParameterMessage("outputPath")));
    } else {
      final List<String> temporalFiles = [];
      final List<String> mutablePaths = [];

      try {
        for (int i = 0; i < inputs.length; i++) {
          final path = await DocumentUtils.prepareInput(inputs[i]);
          if (inputs[i].bytes != null) {
            temporalFiles.add(path);
          }

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
              final temporalOutputPath = kIsWeb
                  ? "document_$i.pdf"
                  : "${DocumentUtils.getTemporalFolderPath()}/document_$i.pdf";
              final response = await PdfCombiner.createPDFFromMultipleImages(
                inputs: [MergeInput.path(path)],
                outputPath: temporalOutputPath,
              );

              mutablePaths.add(response);
              temporalFiles.add(response);
            } else {
              mutablePaths.add(path);
            }
          }
        }

        final response = await PdfCombiner.mergeMultiplePDFs(
          inputs: mutablePaths.map((p) => MergeInput.path(p)).toList(),
          outputPath: outputPath,
        );

        return response;
      } finally {
        DocumentUtils.removeTemporalFiles(temporalFiles);
      }
    }
  }

  /// Combines multiple PDF files into a single PDF.
  ///
  /// This method takes a list of [MergeInput] inputs which can be created from
  /// file paths, raw bytes ([Uint8List]), or [File] objects.
  /// It also takes an `outputPath` where the resulting combined PDF should be saved.
  ///
  /// If the operation is successful, it returns the result from the platform-specific implementation.
  /// If an error occurs, it returns a message describing the error.
  ///
  /// Parameters:
  /// - `inputs`: A list of [MergeInput] representing the PDF files or bytes to be combined.
  /// - `outputPath`: A string representing the directory where the combined PDF should be saved.
  ///
  /// Returns:
  /// - A `Future<String>` representing the result of the operation (either the success message or an error message).
  static Future<String> mergeMultiplePDFs({
    required List<MergeInput> inputs,
    required String outputPath,
  }) async {
    if (inputs.isEmpty) {
      throw PdfCombinerException(
          PdfCombinerMessages.emptyParameterMessage("inputs"));
    }

    final List<String> temporalFiles = [];
    try {
      final List<String> inputPaths = [];
      for (int i = 0; i < inputs.length; i++) {
        final path = await DocumentUtils.prepareInput(inputs[i]);
        if (inputs[i].bytes != null) {
          temporalFiles.add(path);
        }
        inputPaths.add(path);
      }
      await _validateMergeInputs(inputPaths, outputPath);

      final response = await MergePdfsIsolate.mergeMultiplePDFs(
          inputPaths: inputPaths, outputPath: outputPath);

      if (response != null &&
          (response == outputPath || response.startsWith("blob:http"))) {
        return response;
      } else {
        throw PdfCombinerException(response ?? "Unknown error during merge");
      }
    } catch (e) {
      throw e is Exception ? e : PdfCombinerException(e.toString());
    } finally {
      DocumentUtils.removeTemporalFiles(temporalFiles);
    }
  }

  /// Creates a PDF from multiple image files.
  ///
  /// This method sends a request to the native platform to create a PDF from the
  /// images specified in the `inputs` parameter. The resulting PDF is saved in the
  /// `outputPath` directory.
  ///
  /// Parameters:
  /// - `inputs`: A list of [MergeInput] representing the images to be converted into a PDF.
  /// - `outputPath`: The directory path where the created PDF should be saved.
  /// - `config`: A configuration object that specifies how to process the images.
  ///   - `rescale`: The scaling configuration for the images (default is the original image).
  ///   - `keepAspectRatio`: Indicates whether to maintain the aspect ratio of the images (default is `true`).
  ///
  /// Returns:
  /// - A `Future<String>` representing the result of the operation (either the success message or an error message).
  static Future<String> createPDFFromMultipleImages({
    required List<MergeInput> inputs,
    required String outputPath,
    PdfFromMultipleImageConfig config = const PdfFromMultipleImageConfig(),
  }) async {
    final outputPathIsPDF = DocumentUtils.hasPDFExtension(outputPath);
    if (!outputPathIsPDF) {
      throw PdfCombinerException(
          PdfCombinerMessages.errorMessageInvalidOutputPath(outputPath));
    } else if (inputs.isEmpty) {
      throw PdfCombinerException(
          PdfCombinerMessages.emptyParameterMessage("inputs"));
    } else {
      final List<String> temporalFiles = [];
      try {
        final List<String> inputPaths = [];

        for (int i = 0; i < inputs.length; i++) {
          final path = await DocumentUtils.prepareInput(inputs[i]);
          if (inputs[i].bytes != null) {
            temporalFiles.add(path);
          }
          inputPaths.add(path);
        }

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
      } finally {
        DocumentUtils.removeTemporalFiles(temporalFiles);
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
  /// This method takes a [MergeInput] input which can be created from
  /// a file path, raw bytes ([Uint8List]), or a [File] object.
  /// The resulting list of images will be saved in the `outputDirPath` directory.
  ///
  /// If the operation is successful, it returns the result from the platform-specific implementation.
  /// If an error occurs, it returns a message describing the error.
  ///
  /// Parameters:
  /// - `input`: A [MergeInput] representing the PDF document to be extracted.
  /// - `outputDirPath`: A string representing the directory where the list of images should be saved.
  /// - `config`: A configuration object that specifies how to process the images.
  ///   - `rescale`: The scaling configuration for the images (default is the original image).
  ///   - `compression`: The image compression level for the images, affecting file size, quality and clarity (default is [ImageCompression.none]).
  ///   - `createOneImage`: Indicates whether to create a single image or separate images for each page (default is `true`).
  ///
  /// Returns:
  /// - A `Future<List<String>>` representing the result of the operation (either the success message or an error message).
  static Future<List<String>> createImageFromPDF({
    required MergeInput input,
    required String outputDirPath,
    ImageFromPdfConfig config = const ImageFromPdfConfig(),
  }) async {
    final List<String> temporalFiles = [];
    try {
      final inputPath = await DocumentUtils.prepareInput(input);
      if (input.bytes != null) {
        temporalFiles.add(inputPath);
      }

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
    } finally {
      DocumentUtils.removeTemporalFiles(temporalFiles);
    }
  }

  static Future<void> _validateMergeInputs(
      List<String> sources, String outputPath) async {
    bool allArePDF = true;
    String? failingInput;

    for (final path in sources) {
      final isPDF = await DocumentUtils.isPDF(path);
      if (!isPDF) {
        allArePDF = false;
        failingInput = path;
        break;
      }
    }

    final outputPathIsPDF = DocumentUtils.hasPDFExtension(outputPath);
    if (!outputPathIsPDF) {
      throw PdfCombinerException(
          PdfCombinerMessages.errorMessageInvalidOutputPath(outputPath));
    } else if (!allArePDF) {
      throw PdfCombinerException(
          PdfCombinerMessages.errorMessagePDF(failingInput.toString()));
    }
  }
}
