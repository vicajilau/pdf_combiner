import 'package:flutter/material.dart';

import '../../models/input_source_type.dart';

Future<InputSourceType?> showFileTypeDialog(BuildContext context) async =>
    showDialog<InputSourceType>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('File Type'),
        content: const Text('Select a file type'),
        actions: [
          TextButton(
            child: const Text('Path'),
            onPressed: () => Navigator.of(context).pop(InputSourceType.path),
          ),
          TextButton(
            child: const Text('Bytes'),
            onPressed: () => Navigator.of(context).pop(InputSourceType.bytes),
          ),
        ],
      ),
    );
