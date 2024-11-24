import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfCombinerViewModel {
  List<String> selectedFiles = []; // List to store selected PDF file paths
  String outputFile = ""; // Path for the combined output file

  // Function to pick PDF files from the device
  Future<void> pickFiles() async {
    bool isGranted =
        await _checkStoragePermission(); // Check storage permission

    if (isGranted) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true, // Allow picking multiple files
      );

      if (result != null && result.files.isNotEmpty) {
        for (var element in result.files) {
          debugPrint("${element.name}, ");
        }
        selectedFiles = result.files.map((file) => file.path!).toList();
      }
    }
  }

  // Function to combine selected PDF files into a single output file
  Future<void> combinePdfs() async {
    if (selectedFiles.isEmpty) return; // If no files are selected, do nothing

    try {
      final directory = await _getOutputDirectory(); // Get the output directory
      final outputFilePath = '${directory.path}/combined_output.pdf';

      final combiner = PdfCombiner();
      await combiner.combine(selectedFiles, outputFilePath); // Combine the PDFs

      outputFile =
          outputFilePath; // Update the output file path after successful combination
    } catch (e) {
      throw Exception('Error combining PDFs: ${e.toString()}');
    }
  }

  // Function to get the appropriate directory for saving the output file
  Future<Directory> _getOutputDirectory() async {
    if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory(); // For iOS, return the documents directory
    } else if (Platform.isAndroid) {
      return Directory(
          '/storage/emulated/0/Download'); // For Android, return the Downloads directory
    } else {
      throw UnsupportedError(
          'Unsupported platform'); // Throw an error if the platform is unsupported
    }
  }

  // Function to check if storage permission is granted (Android-specific)
  Future<bool> _checkStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage
          .request(); // Request storage permission on Android
      return status.isGranted; // Return whether the permission is granted
    }
    return true; // For iOS, no permission is needed
  }

  // Function to copy the output file path to the clipboard
  Future<void> copyOutputToClipboard() async {
    if (outputFile.isNotEmpty) {
      await Clipboard.setData(
          ClipboardData(text: outputFile)); // Copy output path to clipboard
    }
  }

  // Function to copy the selected files' paths to the clipboard
  Future<void> copySelectedFilesToClipboard(int index) async {
    if (selectedFiles.isNotEmpty) {
      await Clipboard.setData(ClipboardData(
          text: selectedFiles[index])); // Copy selected files to clipboard
    }
  }
}
