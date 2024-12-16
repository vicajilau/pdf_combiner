import 'mock_pdf_combiner_platform.dart';

/// A mock platform that simulates an error when calling the [mergeMultiplePDF] method.
/// It extends [MockPdfCombinerPlatform] and overrides the [mergeMultiplePDF] method
/// to return an error instead of a successful result.
class MockPdfCombinerPlatformWithError extends MockPdfCombinerPlatform {
  /// Overrides the [mergeMultiplePDF] method to simulate an error.
  ///
  /// This method will throw an error with the message 'Simulated Error' when called.
  @override
  Future<String?> mergeMultiplePDFs({
    required List<String> inputPaths,
    required String outputPath,
  }) {
    return Future.error('Simulated Error');
  }
}
