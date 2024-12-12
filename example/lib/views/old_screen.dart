import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_combiner/pdf_combiner.dart';
import 'package:pdf_combiner/responses/image_from_pdf_response.dart';
import 'package:pdf_combiner/responses/merge_multiple_pdf_response.dart';
import 'package:pdf_combiner/responses/pdf_from_multiple_image_response.dart';
import 'package:pdf_combiner_example/utils/custom_logs.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<PlatformFile> files = [];
  List<String> filesPath = [];
  String singleFile = "";

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PDF Merger'),
        ),
        body: Center(
          child: Container(
              margin: const EdgeInsets.all(25),
              child: Column(children: [
                TextButton(
                  style: ButtonStyle(overlayColor:
                      WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                    if (states.contains(WidgetState.focused)) {
                      return Colors.red;
                    }
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.green;
                    }
                    if (states.contains(WidgetState.pressed)) {
                      return Colors.blue;
                    }
                    return Colors.black; // Defer to the widget's default.
                  })),
                  child: const Text(
                    "Chose File",
                    style: TextStyle(fontSize: 14.0),
                  ),
                  onPressed: () {
                    multipleFilePicker();
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  style: ButtonStyle(overlayColor:
                      WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                    if (states.contains(WidgetState.focused)) {
                      return Colors.red;
                    }
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.green;
                    }
                    if (states.contains(WidgetState.pressed)) {
                      return Colors.blue;
                    }
                    return Colors.black; // Defer to the widget's default.
                  })),
                  child: const Text(
                    "Merge Multiple PDF",
                    style: TextStyle(fontSize: 14.0),
                  ),
                  onPressed: () {
                    callMethod(1);
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  style: ButtonStyle(overlayColor:
                      WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                    if (states.contains(WidgetState.focused)) {
                      return Colors.red;
                    }
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.green;
                    }
                    if (states.contains(WidgetState.pressed)) {
                      return Colors.blue;
                    }
                    return Colors.black; // Defer to the widget's default.
                  })),
                  child: const Text(
                    "Create PDF From Multiple Image",
                    style: TextStyle(fontSize: 14.0),
                  ),
                  onPressed: () {
                    callMethod(2);
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  style: ButtonStyle(overlayColor:
                      WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                    if (states.contains(WidgetState.focused)) {
                      return Colors.red;
                    }
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.green;
                    }
                    if (states.contains(WidgetState.pressed)) {
                      return Colors.blue;
                    }
                    return Colors.black; // Defer to the widget's default.
                  })),
                  child: const Text(
                    "Create Image From PDF",
                    style: TextStyle(fontSize: 14.0),
                  ),
                  onPressed: () {
                    singleFilePicker();
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  style: ButtonStyle(overlayColor:
                      WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                    if (states.contains(WidgetState.focused)) {
                      return Colors.red;
                    }
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.green;
                    }
                    if (states.contains(WidgetState.pressed)) {
                      return Colors.blue;
                    }
                    return Colors.black; // Defer to the widget's default.
                  })),
                  child: const Text(
                    "Clear",
                    style: TextStyle(fontSize: 14.0),
                  ),
                  onPressed: () {
                    clear();
                  },
                ),
                const SizedBox(height: 10),
              ])),
        ),
      ),
    );
  }

  clear() {
    files = [];
    filesPath = [];
    singleFile = "";
  }

  Future<void> multipleFilePicker() async {
    bool isGranted = await checkPermission();

    if (isGranted) {
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
            allowMultiple: true,
            type: FileType.custom,
            allowedExtensions: ['jpg', 'pdf']);

        if (result != null) {
          files.addAll(result.files);

          for (int i = 0; i < result.files.length; i++) {
            filesPath.add(result.files[i].path!);
          }
        } else {
          // User canceled the picker
        }
      } on Exception catch (e) {
        printInDebug('never reached$e');
      }
    }
  }

  Future<void> singleFilePicker() async {
    bool isGranted = GetPlatform.isIOS || GetPlatform.isAndroid
        ? await checkPermission()
        : true;

    if (isGranted) {
      try {
        FilePickerResult? result =
            await FilePicker.platform.pickFiles(allowMultiple: false);
        if (result != null) {
          singleFile = result.files[0].path!;
          callMethod(3);
        } else {
          // User canceled the picker
        }
      } on Exception catch (e) {
        printInDebug('never reached$e');
      }
    }
  }

  Future<void> callMethod(int type) async {
    switch (type) {
      case 1:
        String dirPath = await getFilePath("TestPDFMerger");
        mergeMultiplePDF(dirPath);
        break;

      case 2:
        String dirPath = await getFilePath("TestPDFMerger");
        createPDFWithMultipleImage(dirPath);
        break;

      case 3:
        String dirPath = await getFilePathImage("TestPDFMerger");
        createImageFromPDF(dirPath);
        break;
    }
  }

  Future<void> mergeMultiplePDF(outputDirPath) async {
    /// Platform messages may fail, so we use a try/catch PlatformException.
    try {
      /// Get response either success or error
      MergeMultiplePDFResponse response = await PdfCombiner.mergeMultiplePDF(
          filePaths: filesPath, outputPath: outputDirPath);

      Get.snackbar("Info", response.message!);

      if (response.status == "success") {
        OpenFile.open(response.response);
      }

      printInDebug(response.status);
    } on PlatformException {
      printInDebug('Failed to get platform version.');
    }
  }

  Future<void> createPDFWithMultipleImage(outputDirPath) async {
    /// Platform messages may fail, so we use a try/catch PlatformException.
    try {
      /// Get response either success or error
      PdfFromMultipleImageResponse response =
          await PdfCombiner.createPDFFromMultipleImage(
              paths: filesPath, outputDirPath: outputDirPath);

      Get.snackbar("Info", response.message!);

      if (response.status == "success") {
        OpenFile.open(response.response);
      }

      printInDebug(response.status);
    } on PlatformException {
      printInDebug('Failed to get platform version.');
    }
  }

  Future<void> createImageFromPDF(outputDirPath) async {
    /// Platform messages may fail, so we use a try/catch PlatformException.
    try {
      /// Get response either success or error
      ImageFromPDFResponse response = await PdfCombiner.createImageFromPDF(
          path: singleFile, outputDirPath: outputDirPath, createOneImage: true);

      Get.snackbar("Info", response.status!);

      if (response.status == "success") {
        OpenFile.open(response.response![0]);
      }

      printInDebug(response.message);
    } on PlatformException {
      printInDebug('Failed to get platform version.');
    }
  }

  Future<bool> checkPermission() async {
    // Solicita permisos para almacenamiento
    var status = await Permission.storage.request();

    // Imprime el estado actual del permiso
    printInDebug(status);

    if (status.isPermanentlyDenied) {
      // Informa al usuario que debe habilitar el permiso desde configuración
      printInDebug("Go to Settings and provide media access");
      return false;
    } else if (status.isGranted) {
      // El permiso fue otorgado
      return true;
    } else {
      // Cualquier otro estado implica que el permiso no fue otorgado
      return false;
    }
  }

  Future<String> getFilePath(String fileStartName) async {
    String path = "";
    if (GetPlatform.isIOS) {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      path = appDocDir.path;
    } else if (GetPlatform.isAndroid) {
      path = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOWNLOADS);
    }

    return "$path/${fileStartName}ABCEFG5.pdf";
  }

  Future<String> getFilePathImage(String fileStartName) async {
    String path = "";
    if (GetPlatform.isIOS) {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      path = appDocDir.path;
    } else if (GetPlatform.isAndroid) {
      path = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOWNLOADS);
    }

    return "$path/${fileStartName}ABCEFG5.png";
  }
}
