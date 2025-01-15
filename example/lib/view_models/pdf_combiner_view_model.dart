import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/image_from_pdf_response.dart';
import 'package:pdf_combiner/responses/merge_multiple_pdf_response.dart';
import 'package:pdf_combiner/responses/pdf_combiner_status.dart';
import 'package:pdf_combiner/responses/pdf_from_multiple_image_response.dart';

class PdfCombinerViewModel {
  List<String> selectedFiles = []; // List to store selected PDF file paths
  List<String> outputFiles = []; // Path for the combined output file

  // Function to pick PDF files from the device (old method)
  Future<void> pickFiles() async {
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

  // Function to pick PDF files with debug log (new method)
  Future<void> pickFilesWithLogs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true, // Allow picking multiple files
    );

    if (result != null && result.files.isNotEmpty) {
      selectedFiles = result.files.map((file) => file.path!).toList();
      for (var file in selectedFiles) {
        debugPrint("Picked file: $file");
      }
    }
  }

  // Function to combine selected PDF files into a single output file
  Future<void> combinePdfs() async {
    if (selectedFiles.length < 2) {
      throw Exception('you need to select more than one document');
    }
    if (selectedFiles.isEmpty) return; // If no files are selected, do nothing

    try {
      MergeMultiplePDFResponse response;
      String outputFilePath  = "combined_output.pdf";
      if(kIsWeb){
        response = await PdfCombiner.mergeMultiplePDFs(
            inputPaths: selectedFiles,
            outputPath: outputFilePath); // Combine the PDFs
        outputFiles = [
          response.response!
        ]; // Update the output file path after successful combination
      }else{
        final directory = await _getOutputDirectory(); // Get the output directory
        outputFilePath = '${directory?.path}/combined_output.pdf';
        response = await PdfCombiner.mergeMultiplePDFs(
            inputPaths: selectedFiles,
            outputPath: outputFilePath); // Combine the PDFs
        outputFiles = [
          outputFilePath
        ]; // Update the output file path after successful combination
      }




        if (response.status == PdfCombinerStatus.success) {
          debugPrint("Combining PDFs success");
        } else {
          throw Exception('Error combining PDFs: ${response.message}');
        }

    } catch (e) {
      throw Exception('Error combining PDFs: ${e.toString()}');
    }
  }

  // Function to create a PDF file from a list of images
  Future<void> createPDFFromImages() async {
    if (selectedFiles.isEmpty) return; // If no files are selected, do nothing

    try {
      final directory = await _getOutputDirectory(); // Get the output directory
      final outputFilePath = '${directory?.path}/combined_output.pdf';
      PdfFromMultipleImageResponse response =
          await PdfCombiner.createPDFFromMultipleImages(
              inputPaths: selectedFiles,
              outputPath: outputFilePath,
              needImageCompressor: false); // Create PDF image

      outputFiles = [
        outputFilePath
      ]; // Update the output file path after successful combination
      if (response.status == PdfCombinerStatus.success) {
        debugPrint("Creation of PDF was success");
      } else {
        throw Exception('Error creating PDF: ${response.message}');
      }
    } catch (e) {
      throw Exception('Error creating PDF: ${e.toString()}');
    }
  }

  // Function to create a PDF file from a list of images
  Future<void> createImagesFromPDF() async {
    if (selectedFiles.isEmpty) return; // If no files are selected, do nothing
    if (selectedFiles.length > 1) {
      throw Exception('Only you can select a single document');
    }
    try {
      final directory = await _getOutputDirectory(); // Get the output directory
      final outputFilePath = '${directory?.path}/combined_output.jpeg';
      ImageFromPDFResponse response = await PdfCombiner.createImageFromPDF(
          inputPath: selectedFiles.first,
          outputPath: outputFilePath); // Create PDF image
      debugPrint("imageFromPDFResponse: \n $response");
      outputFiles = response
          .response!; // Update the output file path after successful combination
      if (response.status == PdfCombinerStatus.success) {
        debugPrint("Creation of Images was success");
      } else {
        throw Exception('Error creating PDF: ${response.message}');
      }
    } catch (e) {
      throw Exception('Error creating PDF: ${e.toString()}');
    }
  }

  // Function to get the appropriate directory for saving the output file
  Future<Directory?> _getOutputDirectory() async {
    if (!kIsWeb) {
      if (Platform.isIOS) {
        return await getApplicationDocumentsDirectory(); // For iOS, return the documents directory
      } else if (Platform.isAndroid) {
        return await getDownloadsDirectory(); // For Android, return the Downloads directory
      } else {
        throw UnsupportedError(
            'Unsupported platform'); // Throw an error if the platform is unsupported
      }
    } else {
      return await null;
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
