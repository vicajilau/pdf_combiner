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

- **Android**: PDF manipulation is done natively using `android.graphics` with Kotlin, with no external dependencies.
- **iOS and macOS**: PDF manipulation is done natively using Swift, with no external dependencies.
- **Linux and Windows**: Employs [PDFium](https://pdfium.googlesource.com/pdfium/) from Google, a C++ library.
- **Web**: Implements [PDFLib](https://pdf-lib.js.org/) in JavaScript for PDF manipulation.

## Features

### Create PDF From Multiple Documents

Combine any number of PDFs and images, in any order, into a single PDF document.

**Required Parameters:**
- `inputPaths`: A list of strings representing the image and PDF file paths.
- `outputPath`: A string representing the absolute path of the file where the generated PDF should be saved. In the case of web, this parameter is ignored. The file extension must be `.pdf`.

```dart
final imagePaths = ["path/to/image1.jpg", "path/to/document1.pdf", "path/to/image2.png"];
final outputPath = "path/to/output.pdf";

GeneratePdfFromDocumentsResponse response = await PdfCombiner.generatePDFFromDocuments(
  inputPaths: imagePaths,
  outputPath: outputPath,
);

if (response.status == PdfCombinerStatus.success) {
  print("File saved to: ${response.outputPath}");
} else if (response.status == PdfCombinerStatus.error) {
  print("Error: ${response.message}");
}
```

### Merge Multiple PDFs

Combine several PDF files into a single document.

**Required Parameters:**
- `inputPaths`: A list of strings representing the paths of the PDF files to combine.
- `outputPath`: A string representing the absolute path of the file where the combined PDF should be saved. In the case of web, this parameter is ignored. The file extension must be `.pdf`.

```dart
final filesPath = ["path/to/file1.pdf", "path/to/file2.pdf"];
final outputPath = "path/to/output.pdf";

MergeMultiplePDFResponse response = await PdfCombiner.mergeMultiplePDFs(
  inputPaths: filesPath,
  outputPath: outputPath,
);

if (response.status == PdfCombinerStatus.success) {
  print("File saved to: ${response.response}");
} else if (response.status == PdfCombinerStatus.error) {
  print("Error: ${response.message}");
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

PdfFromMultipleImageResponse response = await PdfCombiner.createPDFFromMultipleImages(
  inputPaths: imagePaths,
  outputPath: outputPath,
);

if (response.status == PdfCombinerStatus.success) {
  print("File saved to: ${response.outputPath}");
} else if (response.status == PdfCombinerStatus.error) {
  print("Error: ${response.message}");
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

PdfFromMultipleImageResponse response = await PdfCombiner.createPDFFromMultipleImages(
  inputPaths: imagePaths,
  outputPath: outputPath,
  config: const PdfFromMultipleImageConfig(
    rescale: ImageScale(width: 480, height: 640),
    keepAspectRatio: true,
  ),
);

if (response.status == PdfCombinerStatus.success) {
  print("File saved to: ${response.outputPath}");
} else if (response.status == PdfCombinerStatus.error) {
  print("Error: ${response.message}");
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

ImageFromPDFResponse response = await PdfCombiner.createImageFromPDF(
  inputPath: pdfFilePath, 
  outputDirPath: outputDirPath,
);

if (response.status == PdfCombinerStatus.success) {
  print("Files generated: ${response.outputPaths}");
} else if (response.status == PdfCombinerStatus.error) {
  print("Error: ${response.message}");
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

ImageFromPDFResponse response = await PdfCombiner.createImageFromPDF(
  inputPaths: imagePaths,
  outputPath: outputPath,
  config: const ImageFromPdfConfig(
    rescale: ImageScale(width: 480, height: 640),
    compression: ImageCompression.custom(35),
    createOneImage: true,
  ),
);
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

Entendido. Aquí tienes la sección del README actualizada con una nota que indica que no se deben usar el return y los callbacks juntos en la misma llamada:

---

### Callbacks with `PdfCombinerDelegate`

The `PdfCombinerDelegate` class is designed to handle progress, success, and error callbacks during the PDF combination process. This delegate can be passed as a parameter to any of the PDF combiner methods, making the return process cleaner and more efficient. While both mechanisms (direct return and callbacks) are supported, using callbacks is recommended for simpler operations.

#### `PdfCombinerDelegate` Class Example Usage

Here's an example of how to use the `PdfCombinerDelegate` with the `mergeMultiplePDFs` method:

```dart
void main() async {
  List<String> inputPaths = ['path/to/file1.pdf', 'path/to/file2.pdf'];
  String outputPath = 'path/to/output.pdf';

  PdfCombinerDelegate delegate = PdfCombinerDelegate(
    onProgress: (progress) {
      print('Progress: ${progress * 100}%');
    },
    onSuccess: (outputPaths) {
      print('Successfully combined PDFs. Output paths: $outputPaths');
    },
    onError: (error) {
      print('Error during PDF combination: $error');
    },
  );

  await PdfCombiner.mergeMultiplePDFs(
    inputPaths: inputPaths,
    outputPath: outputPath,
    delegate: delegate,
  );
}
```

**Note:** When using the `PdfCombinerDelegate` for callbacks, do not use the return value from the `await` call in the same method. This prevents duplicate handling of the result, as the callbacks will already manage the progress, success, and error states.

In this example, the `PdfCombinerDelegate` is used to handle progress updates, successful completion, and errors during the PDF combination process. The `mergeMultiplePDFs` method takes the delegate as an optional parameter and triggers the appropriate callbacks based on the operation's outcome.

## Usage

This plugin works with `file_picker` or `image_picker` for selecting files. Ensure you handle permissions using `permission_handler` before invoking the plugin.

### Dependencies

The `pdf_combiner` plugin does not directly use the following dependencies. They are mentioned only to guide the development of solutions that might require additional steps for file selection or permissions:

- [file_picker](https://pub.dev/packages/file_picker)
- [image_picker](https://pub.dev/packages/image_picker)
- [permission_handler](https://pub.dev/packages/permission_handler)

## Supported Platforms

This plugin supports **Android**, **iOS**, **Linux**, **macOS** and **web** directly, no additional setup is required.

> **As of version 3.3.0 on the web**: The `pdf_combiner.js` JavaScript file is now loaded dynamically, eliminating the need to manually include it and import it into the index.html file.

### Old Web Integration (Prior to Version 3.3.0)

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