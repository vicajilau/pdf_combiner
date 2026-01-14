import 'dart:async';
import 'dart:io';

import 'package:file_magic_number/file_magic_number.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;

import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/isolates/images_from_pdf_isolate.dart';
import 'package:pdf_combiner/isolates/merge_pdfs_isolate.dart';
import 'package:pdf_combiner/isolates/pdf_from_multiple_images_isolate.dart';
import 'package:pdf_combiner/models/pdf_from_multiple_image_config.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/responses/pdf_combiner_messages.dart';
import 'package:pdf_combiner/utils/document_utils.dart';

/// `PdfCombiner` updated to support automatic HEIC conversion
class PdfCombiner {
  /// Flag to enable mocking (for testing purposes)
  static bool isMock = false;

  /// Converts HEIC images to JPEG using the `image` package (cross-platform)
  static Future<String> _convertHeicToJpeg(String heicPath) async {
    final bytes = await File(heicPath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw PdfCombinerException("Failed to decode HEIC image: $heicPath");
    }

    final jpegPath = heicPath.replaceAll(RegExp(r'\.heic$', caseSensitive: false), '.jpg');
    final jpegBytes = img.encodeJpg(image, quality: 90);
    await File(jpegPath).writeAsBytes(jpegBytes);
    return jpegPath;
  }

  /// Prepares the input files by automatically converting HEIC to JPEG
  static Future<List<String>> _prepareFiles(List<String> inputPaths) async {
    final List<String> cleanPaths = [];
    for (var path in inputPaths) {
      final fileType = await FileMagicNumber.detectFileTypeFromPathOrBlob(path);
      if (fileType == FileMagicNumberType.heic) {
        path = await _convertHeicToJpeg(path);
      }
      cleanPaths.add(path);
    }
    return cleanPaths;
  }

  /// Combines multiple documents (PDFs or images) into a single PDF
  static Future<String> generatePDFFromDocuments({
    required List<String> inputPaths,
    required String outputPath,
  }) async {
    if (inputPaths.isEmpty) {
      throw PdfCombinerException(
          PdfCombinerMessages.emptyParameterMessage("inputPaths"));
    } else if (outputPath.trim().isEmpty) {
      throw PdfCombinerException(
          PdfCombinerMessages.emptyParameterMessage("outputPath"));
    }

    // Prepare files (convert HEIC automatically)
    final mutablePaths = await _prepareFiles(inputPaths);

    for (int i = 0; i < mutablePaths.length; i++) {
      String path = mutablePaths[i];

      final isPDF = await DocumentUtils.isPDF(path);
      final isImage = await DocumentUtils.isImage(path);
      final outputPathIsPDF = DocumentUtils.hasPDFExtension(outputPath);

      if (!outputPathIsPDF) {
        throw PdfCombinerException(
            PdfCombinerMessages.errorMessageInvalidOutputPath(outputPath));
      } else if (!isPDF && !isImage) {
        throw PdfCombinerException(PdfCombinerMessages.errorMessageMixed(path));
      } else if (isImage) {
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

    final response = await PdfCombiner.mergeMultiplePDFs(
      inputPaths: mutablePaths,
      outputPath: outputPath,
    );

    DocumentUtils.removeTemporalFiles(mutablePaths);

    return response;
  }

  /// Merges multiple PDF files into a single PDF
  static Future<String> mergeMultiplePDFs({
    required List<String> inputPaths,
    required String outputPath,
  }) async {
    if (inputPaths.isEmpty) {
      throw PdfCombinerException(
          PdfCombinerMessages.emptyParameterMessage("inputPaths"));
    }

    try {
      bool allPDFs = true;
      String path = "";

      for (var p in inputPaths) {
        if (!await DocumentUtils.isPDF(p)) {
          allPDFs = false;
          path = p;
          break;
        }
      }

      final outputPathIsPDF = DocumentUtils.hasPDFExtension(outputPath);
      if (!outputPathIsPDF) {
        throw PdfCombinerException(
            PdfCombinerMessages.errorMessageInvalidOutputPath(outputPath));
      } else if (!allPDFs) {
        throw PdfCombinerException(PdfCombinerMessages.errorMessagePDF(path));
      }

      final String? response = await MergePdfsIsolate.mergeMultiplePDFs(
          inputPaths: inputPaths, outputPath: outputPath);

      if (response != null &&
          (response == outputPath || response.startsWith("blob:http"))) {
        return response;
      }

      throw PdfCombinerException(response ?? PdfCombinerMessages.errorMessage);
    } catch (e) {
      throw e is Exception ? e : PdfCombinerException(e.toString());
    }
  }

  /// Creates a PDF from multiple image files
  static Future<String> createPDFFromMultipleImages({
    required List<String> inputPaths,
    required String outputPath,
    PdfFromMultipleImageConfig config = const PdfFromMultipleImageConfig(),
  }) async {
    if (inputPaths.isEmpty) {
      throw PdfCombinerException(
          PdfCombinerMessages.emptyParameterMessage("inputPaths"));
    }

    final List<String> processedPaths = await _prepareFiles(inputPaths);

    try {
      for (var path in processedPaths) {
        if (!await DocumentUtils.isImage(path)) {
          throw PdfCombinerException(PdfCombinerMessages.errorMessageImage(path));
        }
      }

      final String? response =
      await PdfFromMultipleImagesIsolate.createPDFFromMultipleImages(
        inputPaths: processedPaths,
        outputPath: outputPath,
        config: config,
      );

      DocumentUtils.removeTemporalFiles(processedPaths);

      if (response != null &&
          (response == outputPath || response.startsWith("blob:http"))) {
        return response;
      } else {
        throw PdfCombinerException(response ?? PdfCombinerMessages.errorMessage);
      }
    } catch (e) {
      throw e is Exception ? e : PdfCombinerException(e.toString());
    }
  }

  /// Extracts images from a PDF
  static Future<List<String>> createImageFromPDF({
    required String inputPath,
    required String outputDirPath,
    ImageFromPdfConfig config = const ImageFromPdfConfig(),
  }) async {
    if (inputPath.trim().isEmpty) {
      throw PdfCombinerException(
          PdfCombinerMessages.emptyParameterMessage("inputPath"));
    }

    if (!await DocumentUtils.isPDF(inputPath)) {
      throw PdfCombinerException(PdfCombinerMessages.errorMessagePDF(inputPath));
    }

    final response = await ImagesFromPdfIsolate.createImageFromPDF(
      inputPath: inputPath,
      outputDirectory: outputDirPath,
      config: config,
    );

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
}
