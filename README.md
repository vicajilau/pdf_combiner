# PDF Combiner
[![pub package](https://img.shields.io/pub/v/http.svg)](https://pub.dev/packages/pdf_combiner)
![CI Status](https://github.com/vicajilau/pdf_combiner/actions/workflows/dart.yml/badge.svg)

A Flutter plugin for combining and manipulating PDF files. The plugin supports Android and iOS platforms and allows for merging multiple PDF files, creating PDFs from images, and extracting images from PDFs.

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

if (response.status == "success") {
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

if (response.status == "success") {
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

if (response.status == "success") {
  // response.response contains a list of output paths as List<String>
  // response.message contains a success message as a String
}
```

## Usage

This plugin works with `file_picker` or `image_picker` for selecting files. Ensure you handle permissions using `permission_handler` before invoking the plugin.

### Dependencies
- [file_picker](https://pub.dev/packages/file_picker)
- [image_picker](https://pub.dev/packages/image_picker)
- [permission_handler](https://pub.dev/packages/permission_handler)

## Support

The plugin supports both Android and iOS platforms.

## Notes

No additional configuration is required for Android or iOS. Ensure the necessary dependencies for file selection and permissions are added to your project.
