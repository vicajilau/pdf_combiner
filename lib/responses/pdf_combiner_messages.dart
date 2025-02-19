class PdfCombinerMessages {
  static const successMessage = "Processed successfully";
  static const errorMessage = "Error in processing";
  static const processingMessage = "Processing start";
  static String emptyParameterMessage(String parameterName) =>
      "The parameter ($parameterName) cannot be empty";

  static String errorMessagePDF(String path) =>
      "File is not of PDF type or does not exist: $path";
  static String errorMessageImage(String path) =>
      "File is not an image or does not exist: $path";
}
