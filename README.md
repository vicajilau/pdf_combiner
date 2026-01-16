<p align="center">
  <a href="https://pub.dev/packages/pdf_combiner">
    <img src="https://raw.githubusercontent.com/vicajilau/pdf_combiner/main/.github/assets/pdf_combiner.png" height="200" alt="PDF Combiner Logo">
  </a>
  <h1 align="center">PDF Combiner</h1>
</p>

<p align="center">
  <a href="https://pub.dev/packages/pdf_combiner">
    <img src="https://img.shields.io/pub/v/pdf_combiner?label=pub.dev&labelColor=333940&logo=dart" alt="Pub Version">
  </a>
  <a href="https://github.com/vicajilau/pdf_combiner/actions/workflows/dart_analyze_unit_test.yml">
    <img src="https://img.shields.io/github/actions/workflow/status/vicajilau/pdf_combiner/dart_analyze_unit_test.yml?branch=main&label=CI&labelColor=333940&logo=github" alt="CI Status">
  </a>
  <a href="https://github.com/vicajilau/pdf_combiner/actions/workflows/publish_pub_dev.yml">
    <img src="https://img.shields.io/github/actions/workflow/status/vicajilau/pdf_combiner/publish_pub_dev.yml?label=CD&labelColor=333940&logo=github" alt="CD Status">
  </a>
  <a href="https://codecov.io/gh/vicajilau/pdf_combiner">
    <img src="https://img.shields.io/codecov/c/github/vicajilau/pdf_combiner?logo=codecov&logoColor=fff&labelColor=333940" alt="Code Coverage">
  </a>
</p>

## Overview

**PDF Combiner** is a Flutter plugin designed for combining and manipulating PDF files. It supports multiple platforms including Android, iOS, Linux, macOS, Windows and web, enabling users to:

- Combine any number of PDFs and images, in any order, into a single PDF.
- Merge multiple PDF files.
- Create PDFs from images.
- Extract images from PDFs.

### Underlying Technologies

- **Android**: PDF manipulation is done natively using `android.graphics` with Kotlin and [PDFBox](https://pdfbox.apache.org/) from Apache but only for merge PDF files.
- **iOS and macOS**: PDF manipulation is done natively using Swift, with no external dependencies.
- **Linux and Windows**: Employs [PDFium](https://pdfium.googlesource.com/pdfium/) from Google, a C++ library.
- **Web**: Implements [PDFLib](https://pdf-lib.js.org/) in JavaScript for PDF manipulation.

### Supported Platforms

This plugin supports **Android**, **iOS**, **Linux**, **macOS** and **web** directly, no additional setup is required.

## Features

### Create PDF From Multiple Documents

Combine any number of PDFs and images, in any order, into a single PDF document.

**Required Parameters:**

- `inputPaths`: A list of strings representing the image and PDF file paths.
- `outputPath`: A string representing the absolute path of the file where the generated PDF should be saved. In the case of web, this parameter is ignored. The file extension must be `.pdf`.

```dart
final imagePaths = ["path/to/image1.jpg", "path/to/document1.pdf", "path/to/image2.png"];
final outputPath = "path/to/output.pdf";

try {
  String response = await PdfCombiner.generatePDFFromDocuments(
    inputPaths: imagePaths,
    outputPath: outputPath,
  );

  print("File saved to: $response");

} catch (e) {
  // If the error is handled by the plugin, a PdfCombinerException is thrown.
  print("Error: $e");
}
```

### Merge Multiple PDFs

Combine several PDF files into a single document.

**Required Parameters:**

- `inputs`: A list of inputs representing the PDF files to combine. It accepts `String` (file paths) and `Uint8List` (bytes).
- `outputPath`: A string representing the absolute path of the file where the combined PDF should be saved. In the case of web, this parameter is ignored. The file extension must be `.pdf`.

```dart
final inputs = ["path/to/file1.pdf", fileinBytes];
final outputPath = "path/to/output.pdf";

try {
  String response = await PdfCombiner.mergeMultiplePDFs(
    inputs: inputs,
    outputPath: outputPath,
  );
  print("File saved to: $response");
} catch (e) {
  // If the error is handled by the plugin, a PdfCombinerException is thrown.
  print("Error: $e");
}
```

### Create PDF From Multiple Images

Convert a list of image files into a single PDF document.

**Required Parameters:**

- `inputPaths`: A list of strings representing the image file paths.
- `outputPath`: A string representing the absolute path of the file where the generated PDF should be saved. In the case of web, this parameter is ignored. The file extension must be `.pdf`.

By default, images are added to the PDF without modifications. If needed, you can customize the scaling, compression, and aspect ratio using a configuration object.

```dart
final imagePaths = ["path/to/image1.jpg", "path/to/image2.jpg"];
final outputPath = "path/to/output.pdf";

try {
  String response = await PdfCombiner.createPDFFromMultipleImages(
    inputPaths: imagePaths,
    outputPath: outputPath,
  );

  print("File saved to: $response");

} catch (e) {
  // If the error is handled by the plugin, a PdfCombinerException is thrown.
  print("Error: $e");
}
```

#### Custom Creation of PDF From Multiple Images

The `PdfFromMultipleImageConfig` class is used to configure how images are processed before creating a PDF.

**Parameters:**

- `rescale` (default: `ImageScale.original`): Defines the scaling configuration for the images.
- `keepAspectRatio` (default: `true`): Ensures that the aspect ratio of the images is preserved when scaling.

Example Usage:

```dart
final imagePaths = ["path/to/image1.jpg", "path/to/image2.jpg"];
final outputPath = "path/to/output.pdf";

try {
  String response = await PdfCombiner.createPDFFromMultipleImages(
    inputPaths: imagePaths,
    outputPath: outputPath,
    config: const PdfFromMultipleImageConfig(
      rescale: ImageScale(width: 480, height: 640),
      keepAspectRatio: true,
    ),
  );
  print("File saved to: $response");

} catch (e) {
  // If the error is handled by the plugin, a PdfCombinerException is thrown.
  print("Error: $e");
}
```

### Create Images From PDF

Extract images from a PDF file.

**Required Parameters:**

- `inputPath`: A string representing the file path of the PDF to extract images from.
- `outputDirPath`: A string representing the directory folder where the extracted images should be saved. In the case of web, this parameter is ignored.

By default, images are extracted in their original format. If needed, you can customize the scaling, compression, and aspect ratio using a configuration object.

```dart
final pdfFilePath = "path/to/input.pdf";
final outputDirPath = "path/to/output";

try {
  List<String> response = await PdfCombiner.createImageFromPDF(
    inputPath: pdfFilePath, 
    outputDirPath: outputDirPath,
  );
  print("Files generated: $response");
} catch (e) {
  // If the error is handled by the plugin, a PdfCombinerException is thrown.
  print("Error: $e");
}
```

### Custom Creation of Images From PDF

The `ImageFromPdfConfig` class is used to configure how images are processed before creating a list of images.

**Parameters:**

- `rescale` (default: `ImageScale.original`): Defines the scaling configuration for the images.
- `compression` (default: `ImageCompression.none`): Sets the compression level for image, affecting file size quality and clarity.
- `createOneImage` (default: `false`): If you want to create a single image with all pages of the PDF or if you want one image per page.

Example Usage:

```dart
final pdfFilePath = "path/to/input.pdf";
final outputDirPath = "path/to/output";

try {
  List<String> response = await PdfCombiner.createImageFromPDF(
    inputPath: pdfFilePath,
    outputDirPath: outputDirPath,
    config: const ImageFromPdfConfig(
      rescale: ImageScale(width: 480, height: 640),
      compression: ImageCompression.custom(35),
      createOneImage: true,
    ),
  );
  print("Files generated: $response");
} catch (e) {
  // If the error is handled by the plugin, a PdfCombinerException is thrown.
  print("Error: $e");
}
```

#### ImageCompression

Represents the compression level of an image, affecting quality and file size.

Predefined Compression Levels
The `ImageCompression` class provides three predefined quality levels:

- **`ImageCompression.none`** (0) → No compression, highest quality, largest file size. (The default).
- **`ImageCompression.low`** (30) → Minimal compression, highest quality, larger file size.
- **`ImageCompression.medium`** (60) → Balanced compression and image clarity.
- **`ImageCompression.high`** (100) → High compression, lower quality, smaller file size.
- **`ImageCompression.custom(int value)`** → Allows for custom quality levels between 1 and 100.

Summary of Supported Cases

| Compression Level | Value Range | Example Usage                 |
|-------------------|-------------|-------------------------------|
| **None**          | `0`         | `ImageCompression.none`       |
| **Low**           | `30`        | `ImageCompression.low`        |
| **Medium**        | `60`        | `ImageCompression.medium`     |
| **High**          | `100`       | `ImageCompression.high`       |
| **Custom**        | `1 - 100`   | `ImageCompression.custom(75)` |

Example Usage:

```dart
final compression = ImageCompression.medium;
print(compression.value); // Output: 60
```

### PdfCombinerException

When an error occurs during an operation, such as a file not being found, an invalid format, or an internal error in PDF processing, the plugin throws a `PdfCombinerException`.

This exception contains:
- `message`: A descriptive message about what went wrong.

You can handle it explicitly if you need more control:

```dart
try {
  // Any PdfCombiner method
} on PdfCombinerException catch (e) {
  print("Plugin Error: ${e.message}");
} catch (e) {
  print("Other Error: $e");
}
```

## Usage

This plugin works with `file_picker` or `image_picker` for selecting files. Ensure you handle permissions using `permission_handler` before invoking the plugin.

### Dependencies

The `pdf_combiner` plugin does not directly use the following dependencies. They are mentioned only to guide the development of solutions that might require additional steps for file selection or permissions:

- [file_picker](https://pub.dev/packages/file_picker)
- [image_picker](https://pub.dev/packages/image_picker)
- [permission_handler](https://pub.dev/packages/permission_handler)

## Migration Guide

This document describes the breaking changes introduced in recent versions of `pdf_combiner` and how to migrate existing projects safely.

---

### Version 5.0.0 (Breaking Changes)

If you are upgrading to **v5.0.0 or later**, please review the following breaking changes carefully.

#### 1. Response Models Removed

The following response classes have been **removed**:

- `GeneratePdfFromDocumentsResponse`
- `MergeMultiplePDFResponse`
- `PdfFromMultipleImageResponse`
- `ImageFromPDFResponse`

The API no longer wraps results in response objects.

#### 2. Primitive Return Types

All public methods now return **primitive values** instead of custom models:

- `Future<String>` → path to the generated PDF/file
- `Future<List<String>>` → paths to generated files

This makes the API simpler and more idiomatic to Dart.

#### 3. Status & Delegates Removed

The following elements are no longer available:

- `PdfCombinerStatus`
- `PdfCombinerDelegate`

The plugin now relies exclusively on:

- Standard Dart `Future`s
- Exceptions for error reporting

#### 4. Error Handling via Exceptions

Instead of checking for status codes, errors are now communicated by throwing a:

- `PdfCombinerException`

Consumers must handle failures using `try-catch`.

### Migration Example

#### Before (v4.x and earlier)

```dart
var response = await PdfCombiner.mergeMultiplePDFs(...);

if (response.status == PdfCombinerStatus.success) {
  print(response.response);
} else {
  print(response.message);
}
```

#### After (v5.0.0+)
```dart
try {
  String path = await PdfCombiner.mergeMultiplePDFs(...);
  print(path);
} catch (e) {
  // If the error is plugin-related, a PdfCombinerException is thrown.
  print(e);
}
```

---

### Version 3.3.0+
No manual configuration is required for web projects using this version or newer.
> **As of version 3.3.0 (Web)**: The `pdf_combiner.js` JavaScript file is now loaded dynamically, eliminating the need to manually include it and import it into the index.html file.

---

### Legacy Web Integration (Before v3.3.0)

For versions older than 3.3.0, follow these steps:

1. **Add the required JavaScript file**  
   Download [pdf_combiner.js](https://github.com/vicajilau/pdf_combiner/blob/main/lib/web/assets/js/pdf_combiner.js) and place it in the `web/assets/js` folder of your Flutter project.

2. **Include the script in your HTML file**  
   Add the following line to the `<head>` section of your `web/index.html` file:

   ```html
   <script src="assets/js/pdf_combiner.js"></script>
    ```

## Notes

- No additional configuration is required for Android, iOS, or MacOS. Ensure the necessary dependencies for file selection and permissions are added to your project.
- Since version 3.3.0, the `pdf_combiner.js` script is automatically loaded in the web platform, making manual inclusion unnecessary for newer versions.
