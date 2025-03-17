import 'dart:io';
import 'dart:typed_data';
import 'package:file_magic_number/file_magic_number.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

/// A helper class to manage test file preparation and output file path creation.
/// This class is used to handle the loading of assets, writing files to disk,
/// and generating output file paths for integration tests.
class TestFileHelper {
  static late String basePath;

  static Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    basePath = directory.path;
  }

  final List<String> assetPaths;

  /// Constructor to initialize the helper with a list of asset paths.
  ///
  /// [assetPaths] List of paths to asset files that will be loaded into the test environment.
  TestFileHelper(this.assetPaths);

  /// Prepares input files by loading them from assets and saving them to the application
  /// document directory for testing purposes.
  ///
  /// Returns a list of file paths for the assets that were loaded and saved.
  Future<List<String>> prepareInputFiles() async {
    List<String> filePaths = [];

    for (String assetPath in assetPaths) {
      // Load the asset data from the root bundle.
      final byteData = await rootBundle.load(assetPath);
      // Define the full file path to save the asset in the documents directory.
      final filePath = '$basePath/${assetPath.split('/').last}';
      final file = File(filePath);
      // Write the asset bytes to a file.
      await file.writeAsBytes(byteData.buffer.asUint8List());
      filePaths
          .add(filePath); // Add the file path to the list of prepared files.
    }

    return filePaths;
  }

  /// Generates a full output file path in the application document directory.
  ///
  /// [outputFileName] The name of the output file to be generated (e.g., 'merged_output.pdf'). If not provided is empty
  ///
  /// Returns the full path where the output file will be saved.
  Future<String> getOutputFilePath([String outputFileName = ""]) async {
    if (outputFileName.isEmpty) {
      return basePath;
    }
    return '$basePath/$outputFileName'; // Return the full output file path.
  }

  Future<bool> verifyPDFUint8List(List<String> outputPaths,List<String> inputPaths) async {
    List<Uint8List> listInputhFiles = await getUint8List(inputPaths);
    List<Uint8List> listOutPuthFiles = await getUint8List(outputPaths);
    var validator;
    for (int i= 0; i < outputPaths.length; i++) {
      for (int j = 0; j < inputPaths.length; j++) {
        validator = await _containsUint8List(listOutPuthFiles.first, listInputhFiles.first);
      }
    }



    return validator;
  }

  Future<List<Uint8List>> getUint8List(List<String> paths) async {
    return await Future.wait(paths.map((path) => FileMagicNumber.getBytesFromPathOrBlob(path)));
  }

 bool _containsUint8List(Uint8List listOuthputh, Uint8List listInputh) {
    bool found = false;
    int numBytes = 0;
      for (int j = listInputh.indexOf(listOuthputh[numBytes]); j < listInputh.length; j++) {
        if (listOuthputh[numBytes] == listInputh[j]) {
          found = true;
          numBytes++;
          break;
        } else {
          found = false;
          numBytes = 0;
        }
      }
      if(found && numBytes >= listInputh.length){
        found = true;
      }

    return found;
  }
}
