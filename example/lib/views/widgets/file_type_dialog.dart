import 'package:flutter/material.dart';
import 'package:pdf_combiner/models/merge_input_type.dart';

Future<MergeInputType?> showFileTypeDialog(BuildContext context) async =>
    showDialog<MergeInputType>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('File Type'),
        content: const Text('Select a file type'),
        actions: [
          TextButton(
            child: const Text('Path'),
            onPressed: () => Navigator.of(context).pop(MergeInputType.path),
          ),
          TextButton(
            child: Text('Bytes'),
            onPressed: () => Navigator.of(context).pop(MergeInputType.bytes),
          ),
        ],
      ),
    );
