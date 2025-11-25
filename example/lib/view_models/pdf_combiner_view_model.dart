import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/pdf_combiner_delegate.dart';
import 'package:platform_detail/platform_detail.dart';

class PdfCombinerViewModel {
  List<File> selectedFiles = []; // List to store selected file

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
    selectedFiles += files.map((file) => File(file.path)).toList();
    outputFiles = [];
  }

  /// Function to check if the selected files list is empty
  bool isEmpty() => selectedFiles.isEmpty;

  Future<void> _addFiles(List<File> files) async {
    selectedFiles += files;
    outputFiles = [];
  }

  /// Function to restart the selected files
  void restart() {
    selectedFiles = [];
    outputFiles = [];
  }

  List<String> _getPaths() => selectedFiles.map((file) => file.path).toList();

  List<File> _getFiles() => selectedFiles;

  Future<List<Uint8List>> _getUint8Lists() async {
    final fileBytes = <Uint8List>[];
    for (final file in selectedFiles) {
      fileBytes.add(await file.readAsBytes());
    }
    return fileBytes;
  }

  /// Function to combine selected PDF files into a single output file using paths
  Future<void> combinePdfsFromString(PdfCombinerDelegate delegate) async {
    if (selectedFiles.length < 2) {
      delegate.onError
          ?.call(Exception('You need to select more than one document.'));
    } else {
      final directory = await _getOutputDirectory();
      String outputFilePath = '${directory?.path}/combined_output.pdf';

      await PdfCombiner.mergeMultiplePDFs(
        inputPaths: _getPaths(),
        outputPath: outputFilePath,
        delegate: delegate,
      ); // Combine the PDFs
    }
  }

  /// Function to combine selected PDF files into a single output file using Files
  Future<void> combinePdfsFromFile(PdfCombinerDelegate delegate) async {
    if (selectedFiles.length < 2) {
      delegate.onError
          ?.call(Exception('You need to select more than one document.'));
    } else {
      final directory = await _getOutputDirectory();
      String outputFilePath = '${directory?.path}/combined_output.pdf';
      await PdfCombiner.mergeMultiplePDFs(
        inputPaths: _getFiles(),
        outputPath: outputFilePath,
        delegate: delegate,
      ); // Combine the PDFs
    }
  }

  /// Function to combine selected PDF files into a single output file using byte data
  Future<void> combinePdfsFromUint8List(PdfCombinerDelegate delegate) async {
    if (selectedFiles.length < 2) {
      delegate.onError
          ?.call(Exception('You need to select more than one document.'));
    } else if (kIsWeb) {
      delegate.onError?.call(Exception(
          'This feature is not available in web for Uint8List data types.'));
    } else {
      final directory = await _getOutputDirectory();
      String outputFilePath = '${directory?.path}/combined_output.pdf';

      await PdfCombiner.mergeMultiplePDFs(
        inputPaths: await _getUint8Lists(),
        outputPath: outputFilePath,
        delegate: delegate,
      ); // Combine the PDFs
    }
  }

  /// Function to create a PDF file from a list of images
  Future<void> createPDFFromImagesFromString(
      PdfCombinerDelegate delegate) async {
    final directory = await _getOutputDirectory();
    String outputFilePath = '${directory?.path}/combined_output.pdf';
    await PdfCombiner.createPDFFromMultipleImages(
      inputPaths: _getPaths(),
      outputPath: outputFilePath,
      delegate: delegate,
    );
  }

  /// Function to create a PDF file from a list of images using Files
  Future<void> createPDFFromImagesFromFile(PdfCombinerDelegate delegate) async {
    final directory = await _getOutputDirectory();
    String outputFilePath = '${directory?.path}/combined_output.pdf';
    await PdfCombiner.createPDFFromMultipleImages(
      inputPaths: _getFiles(),
      outputPath: outputFilePath,
      delegate: delegate,
    );
  }

  /// Function to create a PDF file from a list of images using byte data
  Future<void> createPDFFromImagesFromUint8List(
      PdfCombinerDelegate delegate) async {
    if (kIsWeb) {
      delegate.onError?.call(Exception(
          'This feature is not available in web for Uint8List data types.'));
    } else {
      final directory = await _getOutputDirectory();
      String outputFilePath = '${directory?.path}/combined_output.pdf';
      await PdfCombiner.createPDFFromMultipleImages(
        inputPaths: await _getUint8Lists(),
        outputPath: outputFilePath,
        delegate: delegate,
      );
    }
  }

  /// Function to create a PDF file from a list of documents
  Future<void> createPDFFromDocumentsFromString(
      PdfCombinerDelegate delegate) async {
    final directory = await _getOutputDirectory();
    String outputFilePath = '${directory?.path}/combined_output.pdf';
    await PdfCombiner.generatePDFFromDocuments(
      inputPaths: _getPaths(),
      outputPath: outputFilePath,
      delegate: delegate,
    );
  }

  /// Function to create a PDF file from a list of documents using Files
  Future<void> createPDFFromDocumentsFromFile(
      PdfCombinerDelegate delegate) async {
    final directory = await _getOutputDirectory();
    String outputFilePath = '${directory?.path}/combined_output.pdf';
    await PdfCombiner.generatePDFFromDocuments(
      inputPaths: _getFiles(),
      outputPath: outputFilePath,
      delegate: delegate,
    );
  }

  /// Function to create a PDF file from a list of documents using byte data
  Future<void> createPDFFromDocumentsFromUint8List(
      PdfCombinerDelegate delegate) async {
    if (kIsWeb) {
      delegate.onError?.call(Exception(
          'This feature is not available in web for Uint8List data types.'));
    } else {
      final directory = await _getOutputDirectory();
      String outputFilePath = '${directory?.path}/combined_output.pdf';
      await PdfCombiner.generatePDFFromDocuments(
        inputPaths: await _getUint8Lists(),
        outputPath: outputFilePath,
        delegate: delegate,
      );
    }
  }

  /// Function to create images from a PDF using a path string
  Future<void> createImagesFromPDFFromString(
      PdfCombinerDelegate delegate) async {
    if (selectedFiles.length > 1) {
      throw Exception('Only you can select a single document.');
    }
    final directory = await _getOutputDirectory();
    final outputFilePath = '${directory?.path}';
    await PdfCombiner.createImageFromPDF(
      inputPath: selectedFiles.first.path,
      outputDirPath: outputFilePath,
      delegate: delegate,
    );
  }

  /// Function to create images from a PDF using a File object
  Future<void> createImagesFromPDFFromFile(PdfCombinerDelegate delegate) async {
    if (selectedFiles.length > 1) {
      throw Exception('Only you can select a single document.');
    }
    final directory = await _getOutputDirectory();
    final outputFilePath = '${directory?.path}';
    await PdfCombiner.createImageFromPDF(
      inputPath: selectedFiles.first.path,
      outputDirPath: outputFilePath,
      delegate: delegate,
    );
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
          text: selectedFiles[index].path)); // Copy selected files to clipboard
    }
  }

  /// Function to remove the selected files
  void removeFileAt(int index) {
    selectedFiles.removeAt(index);
  }
}
