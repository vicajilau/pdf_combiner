import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/isolates/images_from_pdf_isolate.dart';
import 'package:pdf_combiner/models/merge_input.dart';
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
  /// - [inputs] A list of file paths to be combined into a single PDF.
  /// - [outputPath] The path where the final merged PDF will be saved.
  ///
  /// ### Returns:
  /// - A [String] object containing the output path.
  ///
  /// ### Errors:
  /// - Returns an error if `inputs` is empty.
  /// - Returns an error if `outputPath` is empty.
  /// - Returns an error if any input file is neither a PDF nor an image.
  /// - Returns an error if the image-to-PDF conversion fails.
  /// - Returns an error if the merging process fails.
  static Future<String> generatePDFFromDocuments({
    required List<MergeInput> inputs,
    required String outputPath,
  }) async {
    final List<MergeInput> newInputs = await DocumentUtils.conversionUrlInputsToPaths(inputs);
    List<String> temporalPaths = [];
    final List<MergeInput> mutablePaths = List.from(newInputs);
    if (newInputs.isEmpty) {
      throw (PdfCombinerException(
          PdfCombinerMessages.emptyParameterMessage("inputs")));
    } else if (outputPath.trim().isEmpty) {
      throw (PdfCombinerException(
          PdfCombinerMessages.emptyParameterMessage("outputPath")));
    } else {
      for (int i = 0; i < newInputs.length; i++) {
        final input = newInputs[i];
        final isPDF = await DocumentUtils.isPDF(input);
        final isImage = await DocumentUtils.isImage(input);
        final outputPathIsPDF = DocumentUtils.hasPDFExtension(outputPath);
        if (!outputPathIsPDF) {
          throw (PdfCombinerException(
              PdfCombinerMessages.errorMessageInvalidOutputPath(outputPath)));
        } else if (!isPDF && !isImage) {
          throw PdfCombinerException(
            PdfCombinerMessages.errorMessageMixed(
              input.path ?? input.bytes.toString(),
            ),
          );
        }
        if (isImage) {
          final response = await PdfCombiner.createPDFFromMultipleImages(
            inputs: [input],
            outputPath: '${DocumentUtils.getTemporalFolderPath()}/$i.pdf',
          );
          temporalPaths.add(response);

          mutablePaths[i] = MergeInput.path(response);
        }
      }
      final response = await PdfCombiner.mergeMultiplePDFs(
        inputs: mutablePaths,
        outputPath: outputPath,
      );

      DocumentUtils.removeTemporalFiles(temporalPaths);

      return response;
    }
  }

  /// Combines multiple PDF files into a single PDF.
  ///
  /// This method takes a list of file paths (`inputs`) representing the PDFs to be combined,
  /// and an `outputPath` where the resulting combined PDF should be saved.
  ///
  /// If the operation is successful, it returns the result from the platform-specific implementation.
  /// If an error occurs, it returns a message describing the error.
  ///
  /// Parameters:
  /// - `inputs`: A list of [MergeInput] representing the paths of the PDF files to be combined.
  /// - `outputPath`: A string representing the directory where the combined PDF should be saved.
  ///
  /// Returns:
  /// - A `Future<String>` representing the result of the operation (either the success message or an error message).
  static Future<String> mergeMultiplePDFs({
    required List<MergeInput> inputs,
    required String outputPath,
  }) async {
    final List<MergeInput> newInputs = await DocumentUtils.conversionUrlInputsToPaths(inputs);
    final temportalFilePaths = <String>[];
    if (newInputs.isEmpty) {
      throw PdfCombinerException(
          PdfCombinerMessages.emptyParameterMessage("inputPaths"));
    } else {
      try {
        bool success = true;
        String? path;

        for (MergeInput input in newInputs) {
          success = await DocumentUtils.isPDF(input);
          path = input.path;
        }

        final outputPathIsPDF = DocumentUtils.hasPDFExtension(outputPath);
        if (!outputPathIsPDF) {
          throw PdfCombinerException(
              PdfCombinerMessages.errorMessageInvalidOutputPath(outputPath));
        } else if (!success) {
          throw PdfCombinerException(PdfCombinerMessages.errorMessagePDF(path));
        } else {
          final inputPaths = await Future.wait(
            newInputs.map(
              (input) async {
                final result = await DocumentUtils.prepareInput(input);
                switch (input.type) {
                  case MergeInputType.bytes:
                    temportalFilePaths.add(result);
                    break;
                  case MergeInputType.path:
                    break;
                  case MergeInputType.url:
                    break;
                }
                return result;
              },
            ),
          );
          final String? response = await MergePdfsIsolate.mergeMultiplePDFs(
            inputPaths: inputPaths,
            outputPath: outputPath,
          );

          if (response != null &&
              (response == outputPath || response.startsWith("blob:"))) {
            return response;
          }

          final exception = PdfCombinerException(
              response ?? PdfCombinerMessages.errorMessage);
          throw exception;
        }
      } catch (e) {
        throw e is Exception ? e : PdfCombinerException(e.toString());
      } finally {
        DocumentUtils.removeTemporalFiles(temportalFilePaths);
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
  /// - `inputs`: A list of [MergeInput] representing the paths of the images to be converted into a PDF.
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
    final List<MergeInput> newInputs = kIsWeb ? inputs : await DocumentUtils.conversionUrlInputsToPaths(inputs);
    final temportalFilePaths = <String>[];
    final outputPathIsPDF = DocumentUtils.hasPDFExtension(outputPath);
    if (!outputPathIsPDF) {
      throw PdfCombinerException(
          PdfCombinerMessages.errorMessageInvalidOutputPath(outputPath));
    } else if (newInputs.isEmpty) {
      throw PdfCombinerException(
          PdfCombinerMessages.emptyParameterMessage("inputPaths"));
    } else {
      try {
        bool success = true;
        String? path;
        int i = 0;

        while (i < newInputs.length && success) {
          success = await DocumentUtils.isImage(newInputs[i]);
          path = newInputs[i].path;
          i++;
        }

        if (!success) {
          throw PdfCombinerException(
              PdfCombinerMessages.errorMessageImage(path ?? ''));
        } else {
          final inputPaths = await Future.wait(
            newInputs.map(
              (input) async {
                final result = await DocumentUtils.prepareInput(input);
                switch (input.type) {
                  case MergeInputType.bytes:
                    temportalFilePaths.add(result);
                    break;
                  case MergeInputType.path:
                    break;
                  case MergeInputType.url:
                    break;
                }
                return result;
              },
            ),
          );
          final String? response =
              await PdfFromMultipleImagesIsolate.createPDFFromMultipleImages(
            inputPaths: inputPaths,
            outputPath: outputPath,
            config: config,
          );
          if (response != null &&
              (response == outputPath || response.startsWith("blob:"))) {
            return response;
          } else {
            throw PdfCombinerException(
                response ?? PdfCombinerMessages.errorMessage);
          }
        }
      } catch (e) {
        throw e is Exception ? e : PdfCombinerException(e.toString());
      } finally {
        DocumentUtils.removeTemporalFiles(temportalFilePaths);
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
    required MergeInput input,
    required String outputDirPath,
    ImageFromPdfConfig config = const ImageFromPdfConfig(),
  }) async {
    final MergeInput newInput = await DocumentUtils.conversionUrlInputsToPaths([input]).then((value) => value.first);
    String? temportalFilePath;
    try {
      bool success = await DocumentUtils.isPDF(newInput);

      if (!success) {
        String inputTypeMessage;

        switch (newInput.type) {
          case MergeInputType.bytes:
            inputTypeMessage = "File in bytes";
            break;

          case MergeInputType.path:
            inputTypeMessage = newInput.path!;
            break;
          case MergeInputType.url:
            inputTypeMessage = newInput.url!;
            break;
        }

        throw PdfCombinerException(PdfCombinerMessages.errorMessagePDF(
          inputTypeMessage,
        ));
      } else {
        final inputPath = await DocumentUtils.prepareInput(newInput);
        switch (newInput.type) {
          case MergeInputType.bytes:
            temportalFilePath = inputPath;
            break;
          case MergeInputType.path:
            break;
          case MergeInputType.url:
            break;
        }
        final response = await ImagesFromPdfIsolate.createImageFromPDF(
          inputPath: inputPath,
          outputDirectory: outputDirPath,
          config: config,
        );

        if (response != null && response.isNotEmpty) {
          if (response.first.startsWith('blob:') ||
              response.first.contains(outputDirPath)) {
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
      if (temportalFilePath != null) {
        DocumentUtils.removeTemporalFiles([temportalFilePath]);
      }
    }
  }
}
