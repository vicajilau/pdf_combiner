class PdfCombinerMessages {
  static const successMessage = "Processed successfully";
  static const errorMessage = "Error in processing";
  static const processingMessage = "Processing start";
  static String emptyParameterMessage(String parameterName) =>
      "The parameter ($parameterName) cannot be empty";

  static String errorMessagePDF(String path) =>
      "Only PDF file allowed. File is not a pdf: $path";
  static String errorMessageImage(String path) =>
      "Only Image file allowed. File is not an image: $path";
  static String errorMessageFile(String path) => "File does not exist: $path";
}
