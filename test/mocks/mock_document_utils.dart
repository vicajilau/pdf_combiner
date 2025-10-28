import 'dart:io';

import 'package:pdf_combiner/utils/document_utils.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDocumentUtils
    with MockPlatformInterfaceMixin
    implements DocumentUtils {
  /// Removes a list of temporary files from the file system.
  /// It iterates through the provided list of file paths and deletes each file if it exists.
  static void removeTemporalFiles(List<String> paths) {
    for (final path in paths) {
      // Ensure we only delete files within the designated temporary folder
      if (path.startsWith("example/assets/temp")) {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    }
  }

  static String getTemporalFolderPath() {
    return './example/assets/temp';
  }
}
