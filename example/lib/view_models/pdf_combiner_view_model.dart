import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/exception/pdf_combiner_exception.dart';
import 'package:pdf_combiner/models/merge_input.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:platform_detail/platform_detail.dart';

class PdfCombinerViewModel {
  List<MergeInput> selectedFiles = []; // List of selected files
  List<String> outputFiles = []; // Path for the combined output file

  /// Function to pick PDF files from the device (old method)
  Future<void> pickFiles(MergeInputType fileType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'heic'],
      allowMultiple: true, // Allow picking multiple files
      withData: true,
    );
    if (result == null) return;
    switch (fileType) {
      case MergeInputType.path:
        selectedFiles +=
            result.files.map((file) => MergeInput.path(file.path!)).toList();
        break;
      case MergeInputType.bytes:
        selectedFiles +=
            result.files.map((file) => MergeInput.bytes(file.bytes!)).toList();
        break;
    }
  }

  /// Function to pick PDF files from the device
  Future<void> addFilesDragAndDrop(
      MergeInputType fileType, List<DropItem> files) async {
    switch (fileType) {
      case MergeInputType.path:
        selectedFiles +=
            files.map((file) => MergeInput.path(file.path)).toList();
        break;
      case MergeInputType.bytes:
        selectedFiles += await Future.wait(
          files.map(
            (file) async => MergeInput.bytes(
              await file.readAsBytes(),
            ),
          ),
        );
        break;
    }

    outputFiles = [];
  }

  /// Function to check if the selected files list is empty
  bool isEmpty() => selectedFiles.isEmpty;

  /// Function to restart the selected files
  void restart() {
    selectedFiles = [];
    outputFiles = [];
  }

  /// Function to combine selected PDF files into a single output file
  Future<String> combinePdfs() async {
    if (selectedFiles.length < 2) {
      throw PdfCombinerException('You need to select more than one document.');
    } else {
      final directory = await _getOutputDirectory();
      String outputFilePath = '${directory?.path}/combined_output.pdf';

      final response = await PdfCombiner.mergeMultiplePDFs(
        inputs: selectedFiles,
        outputPath: outputFilePath,
      ); // Combine the PDFs
      outputFiles = [response];
      return response;
    }
  }

  /// Function to create a PDF file from a list of images
  Future<String> createPDFFromImages() async {
    final directory = await _getOutputDirectory();
    String outputFilePath = '${directory?.path}/combined_output.pdf';
    final response = await PdfCombiner.createPDFFromMultipleImages(
      inputs: selectedFiles,
      outputPath: outputFilePath,
    );
    outputFiles = [response];
    return response;
  }

  /// Function to create a PDF file from a list of documents
  Future<String> createPDFFromDocuments() async {
    final directory = await _getOutputDirectory();
    String outputFilePath = '${directory?.path}/combined_output.pdf';
    final response = await PdfCombiner.generatePDFFromDocuments(
      inputs: selectedFiles,
      outputPath: outputFilePath,
    );
    outputFiles = [response];
    return response;
  }

  /// Function to create a PDF file from a list of images
  Future<String> createImagesFromPDF() async {
    if (selectedFiles.length > 1) {
      throw PdfCombinerException('Only you can select a single document.');
    }
    final directory = await _getOutputDirectory();
    final outputFilePath = '${directory?.path}';
    final response = await PdfCombiner.createImageFromPDF(
      input: selectedFiles.first,
      outputDirPath: outputFilePath,
    );
    outputFiles = response;
    return response.toString();
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
      await Clipboard.setData(
          ClipboardData(text: selectedFiles[index].toString()));
    }
  }

  /// Function to remove the selected files
  void removeFileAt(int index) {
    selectedFiles.removeAt(index);
  }
}
