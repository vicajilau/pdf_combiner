import 'package:flutter/material.dart';
import 'package:pdf_combiner/models/merge_input.dart';

class FileTypeSelection {
  final MergeInputType type;
  final String? url;

  const FileTypeSelection(this.type, {this.url});
}

class RadioGroupItem<T> {
  final T value;
  final String label;
  const RadioGroupItem(this.value, this.label);
}

class RadioGroupFileType<T> extends StatelessWidget {
  final T groupValue;
  final ValueChanged<T?> onChanged;
  final List<RadioGroupItem<T>> items;

  const RadioGroupFileType({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        return InkWell(
          onTap: () => onChanged(item.value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: RadioGroup<T>(
              groupValue: groupValue,
              onChanged: onChanged,
              child: ListTile(
                title: Text(item.label),
                leading: Radio<T>(toggleable: true, value: item.value),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

Future<FileTypeSelection?> showFileTypeDialog(BuildContext context,
    {bool isDrag = false}) async {
  return showDialog<FileTypeSelection>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      MergeInputType selected = MergeInputType.path;
      final controller = TextEditingController();

      return StatefulBuilder(builder: (context, setState) {
        final isUrlSelected = selected == MergeInputType.url;
        final canAccept = (!isUrlSelected || controller.text.trim().isNotEmpty);

        return AlertDialog(
          title: const Text('File Type'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioGroupFileType<MergeInputType>(
                  groupValue: selected,
                  onChanged: (v) => setState(() => selected = v!),
                  items: isDrag
                      ? const [
                          RadioGroupItem(MergeInputType.path, 'Path'),
                          RadioGroupItem(MergeInputType.bytes, 'Bytes'),
                        ]
                      : const [
                          RadioGroupItem(MergeInputType.path, 'Path'),
                          RadioGroupItem(MergeInputType.bytes, 'Bytes'),
                          RadioGroupItem(MergeInputType.url, 'Url'),
                        ],
                ),
                if (isUrlSelected)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      decoration:
                          const InputDecoration(hintText: 'https://...'),
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(null),
            ),
            TextButton(
              onPressed: canAccept
                  ? () {
                      final url = controller.text.trim();
                      if (selected == MergeInputType.url) {
                        Navigator.of(context)
                            .pop(FileTypeSelection(selected, url: url));
                      } else {
                        Navigator.of(context).pop(FileTypeSelection(selected));
                      }
                    }
                  : null,
              child: const Text('Accept'),
            ),
          ],
        );
      });
    },
  );
}
