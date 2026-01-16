import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// A helper class to manage test file preparation and output file path creation.
class TestFileHelper {
  static late String basePath;

  static Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    basePath = directory.path;
  }

  final List<String> assetPaths;
  final String _uniquePrefix;

  /// Constructor with a unique prefix to avoid file locking issues on Windows
  TestFileHelper(this.assetPaths) : _uniquePrefix = _generateRandomString(5);

  static String _generateRandomString(int len) {
    var r = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(len, (index) => chars[r.nextInt(chars.length)]).join();
  }

  /// Prepares input files with unique names
  Future<List<String>> prepareInputFiles() async {
    List<String> filePaths = [];

    for (String assetPath in assetPaths) {
      final byteData = await rootBundle.load(assetPath);
      final fileName = p.basename(assetPath);
      final filePath = p.join(basePath, '${_uniquePrefix}_$fileName');
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      filePaths.add(filePath);
    }

    return filePaths;
  }

  /// Generates a unique full output file path
  Future<String> getOutputFilePath([String outputFileName = ""]) async {
    if (outputFileName.isEmpty) {
      return basePath;
    }
    return p.join(basePath, outputFileName);
  }

  Future<void> deleteFiles() async {
    for (String assetPath in assetPaths) {
      final fileName = p.basename(assetPath);
      final filePath = p.join(basePath, '${_uniquePrefix}_$fileName');
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      print("Deleted file: $filePath");
    }
  }
}
