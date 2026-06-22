import 'package:file_magic_number/file_magic_number.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf_combiner/models/merge_input.dart';

class FileTypeIcon extends StatelessWidget {
  final MergeInput input;
  const FileTypeIcon({super.key, required this.input});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        if (input.path != null) {
          OpenFile.open(input.path!);
        }
      },
      child: FutureBuilder(
          future: () {
            if (input.bytes != null) {
              return Future.value(
                  FileMagicNumber.detectFileTypeFromBytes(input.bytes!));
            }
            if (input.path != null) {
              return FileMagicNumber.detectFileTypeFromPathOrBlob(input.path!);
            }
            return Future.value(null);
          }(),
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
                case FileMagicNumberType.heic:
                  return Image.asset("assets/files/heic_file.png");
                default:
                  return Image.asset("assets/files/unknown_file.png");
              }
            }
          }),
    );
  }
}
