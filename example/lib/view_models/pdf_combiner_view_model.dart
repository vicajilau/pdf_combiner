import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/models/image_from_pdf_config.dart';
import 'package:pdf_combiner/models/image_scale.dart';
import 'package:pdf_combiner/models/pdf_from_multiple_image_config.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';
import 'package:platform_detail/platform_detail.dart';

class PdfCombinerViewModel {
  List<String> selectedFiles = []; // List to store selected PDF file paths
  List<String> outputFiles = []; // Path for the combined output file

  /// Function to pick PDF files from the device (old method)
  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
      allowMultiple: true, // Allow picking multiple files
    );

    if (result != null && result.files.isNotEmpty) {
      for (var element in result.files) {
        debugPrint("${element.name}, ");
      }
      final files = result.files
          .where((file) => file.path != null)
          .map((file) => File(file.path!))
          .toList();
      _addFiles(files);
    }
  }

  /// Function to pick PDF files from the device
  Future<void> addFilesDragAndDrop(List<DropItem> files) async {
    selectedFiles += files.map((file) => file.path).toList();
    outputFiles = [];
  }

  /// Function to check if the selected files list is empty
  bool isEmpty() => selectedFiles.isEmpty;

  /// Function to pick PDF files from the device
  Future<void> _addFiles(List<File> files) async {
    selectedFiles += files.map((file) => file.path).toList();
    outputFiles = [];
  }

  /// Function to restart the selected files
  void restart() {
    selectedFiles = [];
    outputFiles = [];
  }

  /// Function to combine selected PDF files into a single output file
  Future<void> combinePdfs() async {
    if (selectedFiles.length < 2) {
      throw Exception('You need to select more than one document.');
    }
    if (selectedFiles.isEmpty) return; // If no files are selected, do nothing

    try {
      String outputFilePath = "combined_output.pdf";
      final directory = await _getOutputDirectory();
      outputFilePath = '${directory?.path}/combined_output.pdf';

      final response = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: selectedFiles,
        outputPath: outputFilePath,
      ); // Combine the PDFs

      if (response.status == PdfCombinerStatus.success) {
        outputFiles = [response.outputPath];
      } else {
        throw Exception('Error combining PDFs: ${response.message}.');
      }
    } catch (e) {
      throw Exception('Error combining PDFs: ${e.toString()}.');
    }
  }

  /// Function to create a PDF file from a list of images
  Future<void> createPDFFromImages() async {
    if (selectedFiles.isEmpty) return; // If no files are selected, do nothing
    String outputFilePath = "combined_output.pdf";
    try {
      final directory = await _getOutputDirectory();
      outputFilePath = '${directory?.path}/combined_output.pdf';
      final response = await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: selectedFiles,
        outputPath: outputFilePath,
        config: PdfFromMultipleImageConfig(
          rescale: ImageScale(width: 480, height: 640),
          keepAspectRatio: true,
        ),
      );

      switch (response.status) {
        case PdfCombinerStatus.success:
          outputFiles = [response.outputPath];
        case PdfCombinerStatus.error:
          throw Exception('Error creating PDF: ${response.message}.');
      }
    } catch (e) {
      throw Exception('Error creating PDF: ${e.toString()}.');
    }
  }

  /// Function to create a PDF file from a list of documents
  Future<void> createPDFFromDocuments() async {
    if (selectedFiles.isEmpty) return; // If no files are selected, do nothing
    try {
        final directory = await _getOutputDirectory();
        String outputFilePath = '${directory?.path}';
      final response = await PdfCombiner.generatePDFFromDocuments(
        inputPaths: selectedFiles,
        outputPath: outputFilePath,
      );

      switch (response.status) {
        case PdfCombinerStatus.success:
          outputFiles = [response.outputPath];
        case PdfCombinerStatus.error:
          throw Exception('Error creating PDF: ${response.message}.');
      }
    } catch (e) {
      throw Exception('Error creating PDF: ${e.toString()}.');
    }
  }

  /// Function to create a PDF file from a list of images
  Future<void> createImagesFromPDF() async {
    if (selectedFiles.isEmpty) return; // If no files are selected, do nothing
    if (selectedFiles.length > 1) {
      throw Exception('Only you can select a single document.');
    }
    try {
      final directory = await _getOutputDirectory();
      final outputFilePath = '${directory?.path}';
      final response = await PdfCombiner.createImageFromPDF(
        inputPath: selectedFiles.first,
        outputDirPath: outputFilePath,
        config: ImageFromPdfConfig(
          rescale: ImageScale(width: 480, height: 640),
          createOneImage: false,
        ),
      );

      if (response.status == PdfCombinerStatus.success) {
        outputFiles = response.outputPaths;
      } else {
        throw Exception('${response.message}.');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Function to get the appropriate directory for saving the output file
  Future<Directory?> _getOutputDirectory() async {
    if (PlatformDetail.isIOS || PlatformDetail.isDesktop) {
      return await getApplicationDocumentsDirectory(); // For iOS & Desktop, return the documents directory
    } else if (PlatformDetail.isAndroid) {
      return await getDownloadsDirectory(); // For Android, return the Downloads directory
    } else if (PlatformDetail.isWeb) {
      return null;
    } else {
      throw UnsupportedError(
          '_getOutputDirectory() in unsupported platform.'); // Throw an error if the platform is unsupported
    }
  }

  /// Function to copy the output file path to the clipboard
  Future<void> copyOutputToClipboard(int index) async {
    if (outputFiles.isNotEmpty) {
      await Clipboard.setData(ClipboardData(
          text: outputFiles[index])); // Copy output path to clipboard
    }
  }

  /// Function to copy the selected files' paths to the clipboard
  Future<void> copySelectedFilesToClipboard(int index) async {
    if (selectedFiles.isNotEmpty) {
      await Clipboard.setData(ClipboardData(
          text: selectedFiles[index])); // Copy selected files to clipboard
    }
  }

  /// Function to remove the selected files
  void removeFileAt(int index) {
    selectedFiles.removeAt(index);
  }
}
