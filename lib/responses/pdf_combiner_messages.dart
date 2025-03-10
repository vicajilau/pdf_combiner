/// Contains predefined messages used in the PDF combiner process.
class PdfCombinerMessages {
  /// Message indicating that the process was successful.
  static const successMessage = "Processed successfully";

  /// Message indicating that an error occurred during processing.
  static const errorMessage = "Error in processing";

  /// Message indicating that processing has started.
  static const processingMessage = "Processing start";

  /// Returns an error message when a required parameter is empty.
  ///
  /// - [parameterName] The name of the parameter that cannot be empty.
  static String emptyParameterMessage(String parameterName) =>
      "The parameter ($parameterName) cannot be empty";

  /// Returns an error message when a file is not a valid PDF or does not exist.
  ///
  /// - [path] The file path of the invalid or non-existent PDF.
  static String errorMessagePDF(String path) =>
      "File is not of PDF type or does not exist: $path";

  /// Returns an error message when a file is not a valid image or does not exist.
  ///
  /// - [path] The file path of the invalid or non-existent image.
  static String errorMessageImage(String path) =>
      "File is not an image or does not exist: $path";

  /// Returns an error message when a file is neither a PDF nor an image, or does not exist.
  ///
  /// - [path] The file path of the invalid or non-existent file.
  static String errorMessageMixed(String path) =>
      "The file is neither a PDF document nor an image or does not exist: $path";
}
