import 'pdf_combiner_platform_interface.dart';

/// The `PdfCombiner` class provides functionality for combining multiple PDF files.
///
/// It communicates with the platform-specific implementation of the PDF combiner using
/// the `PdfCombinerPlatform` interface. This class exposes a method to combine PDFs
/// and handles errors that may occur during the process.
class PdfCombiner {

  /// Combines multiple PDF files into a single PDF.
  ///
  /// This method takes a list of file paths (`filePaths`) representing the PDFs to be combined,
  /// and an `outputPath` where the resulting combined PDF should be saved.
  ///
  /// If the operation is successful, it returns the result from the platform-specific implementation.
  /// If an error occurs, it returns a message describing the error.
  ///
  /// Parameters:
  /// - `filePaths`: A list of strings representing the paths of the PDF files to be combined.
  /// - `outputPath`: A string representing the directory where the combined PDF should be saved.
  ///
  /// Returns:
  /// - A `Future<String?>` representing the result of the operation (either the success message or an error message).
  Future<String?> combine(List<String> filePaths, String outputPath) async {
    try {
      // Use the mergeMultiplePDF method from the platform interface
      final result = await PdfCombinerPlatform.instance.mergeMultiplePDF(
        paths: filePaths,
        outputDirPath: outputPath,
      );
      return result;  // Returns the result from the native method
    } catch (e) {
      // In case of error, returns an error message
      return 'Error combining the PDFs: $e';
    }
  }
}
