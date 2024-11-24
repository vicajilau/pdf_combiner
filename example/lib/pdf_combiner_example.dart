import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfCombinerExample extends StatefulWidget {
  const PdfCombinerExample({super.key});

  @override
  State<PdfCombinerExample> createState() => _PdfCombinerExampleState();
}

class _PdfCombinerExampleState extends State<PdfCombinerExample> {
  List<String> selectedFiles = []; // List to store selected PDF file paths
  String outputFile = ""; // Path for the combined output file

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Combiner Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickFiles, // Button to pick files
              child: const Text('Select PDF Files'),
            ),
            ElevatedButton(
              onPressed: selectedFiles.isNotEmpty
                  ? _combinePdfs
                  : null, // Button to combine PDFs (enabled only if files are selected)
              child: const Text('Combine PDFs'),
            ),
            const SizedBox(height: 20),
            Text(
              'Selected Files:\n${selectedFiles.join('\n')}', // Display selected files
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Text(
              'Output File:\n$outputFile', // Display the output file path
              style: const TextStyle(fontSize: 14, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to show SnackBar safely, checking if the widget is still mounted
  void _showSnackbarSafely(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message))); // Show message in SnackBar
    }
  }

  // Function to pick PDF files from the device
  Future<void> _pickFiles() async {
    bool isGranted =
        await _checkStoragePermission(); // Check storage permission

    if (isGranted) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true, // Allow picking multiple files
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          selectedFiles = result.files
              .map((file) => file.path!)
              .toList(); // Store selected file paths
        });
      }
    } else {
      _showSnackbarSafely(
          'Storage permission is required'); // Show a message if permission is not granted
    }
  }

  // Function to combine selected PDF files into a single output file
  Future<void> _combinePdfs() async {
    if (selectedFiles.isEmpty) return; // If no files are selected, do nothing

    try {
      final directory = await _getOutputDirectory(); // Get the output directory
      final outputFilePath =
          '${directory.path}/combined_output.pdf'; // Define output file path

      final combiner = PdfCombiner();
      await combiner.combine(selectedFiles, outputFilePath); // Combine the PDFs

      setState(() {
        outputFile =
            outputFilePath; // Update the output file path after successful combination
      });

      _showSnackbarSafely(
          'PDFs combined successfully: $outputFilePath'); // Show success message
    } catch (e) {
      _showSnackbarSafely(
          'Error: ${e.toString()}'); // Show error message if combining fails
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
}
