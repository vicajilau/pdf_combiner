import 'package:file_magic_number/file_magic_number.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

class FileTypeIcon extends StatelessWidget {
  final String filePath;
  const FileTypeIcon({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () => OpenFile.open(filePath),
        child: FutureBuilder(
            future: FileMagicNumber.detectFileTypeFromPathOrBlob(filePath),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return const Icon(Icons.error);
              } else {
                switch (snapshot.data) {
                  case FileMagicNumberType.png:
                    return Image.asset("assets/files/png_file.png");
                  case FileMagicNumberType.jpg:
                    return Image.asset("assets/files/jpg_file.png");
                  case FileMagicNumberType.pdf:
                    return Image.asset("assets/files/pdf_file.png");
                  default:
                    return Image.asset("assets/files/unknown_file.png");
                }
              }
            }));
  }
}
