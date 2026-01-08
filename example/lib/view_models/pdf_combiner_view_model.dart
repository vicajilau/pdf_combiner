import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
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
  Future<dynamic> combinePdfs() async {
    if (selectedFiles.length < 2) {
      throw PdfCombinerException('You need to select more than one document.');
    } else {
      final directory = await _getOutputDirectory();
      String outputFilePath = '${directory?.path}/combined_output.pdf';

      final response = await PdfCombiner.mergeMultiplePDFs(
        inputPaths: selectedFiles,
        outputPath: outputFilePath,
      ); // Combine the PDFs
      outputFiles = [response.outputPath];
      return response.outputPath;
    }
  }

  /// Function to create a PDF file from a list of images
  Future<dynamic> createPDFFromImages() async {
    final directory = await _getOutputDirectory();
    String outputFilePath = '${directory?.path}/combined_output.pdf';
    final response = await PdfCombiner.createPDFFromMultipleImages(
      inputPaths: selectedFiles,
      outputPath: outputFilePath,
    );
    outputFiles = [response.outputPath];
    return response.outputPath;
  }

  /// Function to create a PDF file from a list of documents
  Future<dynamic> createPDFFromDocuments() async {
    final directory = await _getOutputDirectory();
    String outputFilePath = '${directory?.path}/combined_output.pdf';
    final response = await PdfCombiner.generatePDFFromDocuments(
      inputPaths: selectedFiles,
      outputPath: outputFilePath,
    );
    outputFiles = [response.outputPath];
    return response.outputPath;
  }

  /// Function to create a PDF file from a list of images
  Future<dynamic> createImagesFromPDF() async {
    if (selectedFiles.length > 1) {
      throw PdfCombinerException('Only you can select a single document.');
    }
    final directory = await _getOutputDirectory();
    final outputFilePath = '${directory?.path}';
    final response = await PdfCombiner.createImageFromPDF(
      inputPath: selectedFiles.first,
      outputDirPath: outputFilePath,
    );
    outputFiles = response.outputPaths;
    return response.outputPaths;
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
