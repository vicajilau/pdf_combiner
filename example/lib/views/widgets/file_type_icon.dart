import 'package:file_magic_number/file_magic_number.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf_combiner/models/merge_input.dart';

class FileTypeIcon extends StatefulWidget {
  final MergeInput input;
  const FileTypeIcon({super.key, required this.input});

  @override
  State<FileTypeIcon> createState() => _FileTypeIconState();
}

class _FileTypeIconState extends State<FileTypeIcon> {
  late Future<FileMagicNumberType> _fileTypeFuture;

  @override
  void initState() {
    super.initState();
    _initFuture();
  }

  @override
  void didUpdateWidget(covariant FileTypeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldInput = oldWidget.input;
    final newInput = widget.input;
    if (oldInput.type != newInput.type ||
        oldInput.path != newInput.path ||
        oldInput.bytes != newInput.bytes) {
      _initFuture();
    }
  }

  void _initFuture() {
    _fileTypeFuture = switch (widget.input.type) {
      MergeInputType.bytes => Future.value(
          FileMagicNumber.detectFileTypeFromBytes(widget.input.bytes!)),
      MergeInputType.path =>
        FileMagicNumber.detectFileTypeFromPathOrBlob(widget.input.path!),
    };
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        switch (widget.input.type) {
          case MergeInputType.path:
            OpenFile.open(widget.input.path!);
          case MergeInputType.bytes:
            null;
        }
      },
      child: FutureBuilder<FileMagicNumberType>(
          future: _fileTypeFuture,
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
