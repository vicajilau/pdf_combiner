import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';
import 'package:platform_detail/platform_detail.dart';

class PdfCombinerViewModel {
  List<String> selectedFiles = []; // List to store selected PDF file paths
  List<String> outputFiles = []; // Path for the combined output file

  // Function to pick PDF files from the device (old method)
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
      selectedFiles += result.files.map((file) => file.path!).toList();
      outputFiles = [];
    }
  }

  // Function to restart the selected files
  void restart() {
    selectedFiles = [];
    outputFiles = [];
  }

  // Function to combine selected PDF files into a single output file
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
          outputPath: outputFilePath); // Combine the PDFs

      if (response.status == PdfCombinerStatus.success) {
        outputFiles = [response.response!];
      } else {
        throw Exception('Error combining PDFs: ${response.message}.');
      }
    } catch (e) {
      throw Exception('Error combining PDFs: ${e.toString()}.');
    }
  }

  // Function to create a PDF file from a list of images
  Future<void> createPDFFromImages() async {
    if (selectedFiles.isEmpty) return; // If no files are selected, do nothing
    String outputFilePath = "combined_output.pdf";
    try {
      final directory = await _getOutputDirectory();
      outputFilePath = '${directory?.path}/combined_output.pdf';
      final response = await PdfCombiner.createPDFFromMultipleImages(
          inputPaths: selectedFiles,
          outputPath: outputFilePath,
          needImageCompressor: false);
      if (response.status == PdfCombinerStatus.success) {
        outputFiles = [response.response!];
      } else {
        throw Exception('Error creating PDF: ${response.message}.');
      }
    } catch (e) {
      throw Exception('Error creating PDF: ${e.toString()}.');
    }
  }

  // Function to create a PDF file from a list of images
  Future<void> createImagesFromPDF() async {
    if (selectedFiles.isEmpty) return; // If no files are selected, do nothing
    if (selectedFiles.length > 1) {
      throw Exception('Only you can select a single document.');
    }
    String outputFilePath = "combined_output.pdf";
    try {
      final directory = await _getOutputDirectory();
      outputFilePath = '${directory?.path}/combined_output.jpeg';
      final response = await PdfCombiner.createImageFromPDF(
          inputPath: selectedFiles.first,
          outputPath: outputFilePath,
          createOneImage: false);

      if (response.status == PdfCombinerStatus.success) {
        outputFiles = response.response!;
      } else {
        throw Exception('${response.message}.');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Function to get the appropriate directory for saving the output file
  Future<Directory?> _getOutputDirectory() async {
    if (PlatformDetail.isIOS ||
        PlatformDetail.isMacOS ||
        PlatformDetail.isLinux) {
      return await getApplicationDocumentsDirectory(); // For iOS & macOS, return the documents directory
    } else if (PlatformDetail.isAndroid) {
      return await getDownloadsDirectory(); // For Android, return the Downloads directory
    } else if (PlatformDetail.isWeb) {
      return null;
    } else {
      throw UnsupportedError(
          '_getOutputDirectory() in unsupported platform.'); // Throw an error if the platform is unsupported
    }
  }

  // Function to copy the output file path to the clipboard
  Future<void> copyOutputToClipboard(int index) async {
    if (outputFiles.isNotEmpty) {
      await Clipboard.setData(ClipboardData(
          text: outputFiles[index])); // Copy output path to clipboard
    }
  }

  // Function to copy the selected files' paths to the clipboard
  Future<void> copySelectedFilesToClipboard(int index) async {
    if (selectedFiles.isNotEmpty) {
      await Clipboard.setData(ClipboardData(
          text: selectedFiles[index])); // Copy selected files to clipboard
    }
  }

  // Function to remove the selected files
  void removeFileAt(int index) {
    selectedFiles.removeAt(index);
  }
}
