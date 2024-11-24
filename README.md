
# pdf_combiner

`pdf_combiner` is a lightweight and efficient Flutter plugin designed to merge multiple PDF documents into a single file effortlessly.

## Features

- Select multiple PDF files.
- Merge selected PDFs into one output file.
- Supports both Android and iOS platforms.
- Handles storage permission requests on Android.
- Displays success and error messages with SnackBars.

## Getting Started

To get started with the `pdf_combiner` plugin, follow the steps below:

### 1. Add the Dependency

Add `pdf_combiner` to your `pubspec.yaml` file:

```yaml
dependencies:
  pdf_combiner: ^0.0.1
```

### 2. Install Dependencies

Run the following command to fetch the package:

```bash
flutter pub get
```

### 3. Android Setup

For Android, you need to configure the app with the appropriate permissions. Open the `AndroidManifest.xml` file in your android/app/src/main directory and add the following permissions:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### 4. iOS Setup

For iOS, ensure that the following permissions are included in your `Info.plist`:

```xml
<key>NSDocumentsFolderUsageDescription</key>
<string>We need access to your documents folder to save the merged PDF</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to select files</string>
```

### 5. Usage Example

Here is a simple example of how to use the pdf_combiner plugin to select and merge PDF files:

```dart
import 'package:pdf_combiner/pdf_combiner.dart';

// Example to combine selected PDFs
PdfCombiner pdfCombiner = PdfCombiner();
await pdfCombiner.combine(selectedFiles, outputFilePath);
```
In the above example, replace `selectedFiles` with the list of file paths of the PDFs to be merged, and `outputFilePath` with the desired output path for the merged file.

### 6. Handling Permissions

On Android, the plugin requests storage permissions to access the selected files. The plugin will automatically handle permission requests when using the `_checkStoragePermission()` method. Ensure your app requests the appropriate permissions when needed.

## Example

A full example of using the `pdf_combiner` plugin in a Flutter app can be found in the `example` directory of this repository. It includes:

- A UI to select PDF files.
- A button to trigger the merge process.
- Displaying output and error messages.

## Contributing

Contributions are welcome! Please feel free to fork this repository and submit pull requests with improvements.

### Steps to contribute:

1. Fork this repository.
2. Clone your fork to your local machine.
3. Make your changes.
4. Push your changes to your fork.
5. Create a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## Contact

For any questions or feedback, feel free to open an issue or contact the repository owner.