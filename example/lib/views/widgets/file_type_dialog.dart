import 'package:flutter/material.dart';

import '../../models/input_source_type.dart';

Future<InputSourceType?> showFileTypeDialog(
  BuildContext context, {
  required bool canUsePath,
}) async =>
    showDialog<InputSourceType>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('How do you want to add the file?'),
        content: Text(
          canUsePath
              ? 'Choose whether to add the files by path or bytes.'
              : 'Choose whether to add the files by bytes. Path is not available on web.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: canUsePath
                ? () => Navigator.of(context).pop(InputSourceType.path)
                : null,
            child: const Text('Path'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(InputSourceType.bytes),
            child: const Text('Bytes'),
          ),
        ],
      ),
    );
