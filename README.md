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

A Flutter plugin for combining and manipulating PDF files. The plugin supports Android, iOS, Linux, MacOS and Web platforms and allows for merging multiple PDF files, creating PDFs from images, and extracting images from PDFs.

### Underlying Technologies

- **Android**: Uses the [PDFBox](https://pdfbox.apache.org/) library from Apache.
- **iOS and macOS**: PDF manipulation is done natively using Swift, with no external dependencies.
- **Linux and Windows**: Utilizes [PDFium](https://pdfium.googlesource.com/pdfium/) from Google, a C++ library.
- **Web**: Uses [PDFLib](https://pdf-lib.js.org/) in JavaScript for PDF manipulation.

## Features

### Merge Multiple PDFs

Combine multiple PDF files into a single document.

**Required Parameters:**
- `inputPaths`: A list of strings representing the paths of the PDF files to be combined.
- `outputPath`: A string representing the directory where the combined PDF should be saved.

```dart
MergeMultiplePDFResponse response = await PdfCombiner.mergeMultiplePDFs(
  inputPaths: filesPath, 
  outputPath: outputDirPath,
);

if (response.status == PdfCombinerStatus.success) {
  // response.response contains the output path as a String
  // response.message contains a success message as a String
}
```

### Create PDF From Multiple Images

Convert a list of image files into a single PDF document.

**Required Parameters:**
- `inputPaths`: A list of strings representing the paths of the image files.
- `outputPath`: A string representing the directory where the generated PDF should be saved.

**Optional Parameters:**
- `maxWidth` (default: 360): Maximum width for image compression.
- `maxHeight` (default: 360): Maximum height for image compression.
- `needImageCompressor` (default: true): Whether to compress the images.

```dart
PdfFromMultipleImageResponse response = await PdfCombiner.createPDFFromMultipleImages(
  inputPaths: imagePaths,
  outputPath: outputPath,
  maxWidth: 480, // Optional
  maxHeight: 640, // Optional
  needImageCompressor: false, // Optional
);

if (response.status == PdfCombinerStatus.success) {
  // response.response contains the output path as a String
  // response.message contains a success message as a String
}
```

### Create Images From PDF

Extract images from a PDF file.

**Required Parameters:**
- `inputPath`: A string representing the file path of the PDF to extract images from.
- `outputPath`: A string representing the directory where the extracted images should be saved.

**Optional Parameters:**
- `maxWidth` (default: 360): Maximum width for the extracted images.
- `maxHeight` (default: 360): Maximum height for the extracted images.
- `createOneImage` (default: true): Whether to create a single composite image from the PDF.

```dart
ImageFromPDFResponse response = await PdfCombiner.createImageFromPDF(
  inputPath: pdfFilePath, 
  outputPath: outputPath,
  maxWidth: 720, // Optional
  maxHeight: 1080, // Optional
  createOneImage: false, // Optional
);

if (response.status == PdfCombinerStatus.success) {
  // response.response contains a list of output paths as List<String>
  // response.message contains a success message as a String
}
```

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
