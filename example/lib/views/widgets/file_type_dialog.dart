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

class RadioGroup<T> extends StatelessWidget {
  final T groupValue;
  final ValueChanged<T?> onChanged;
  final List<RadioGroupItem<T>> items;

  const RadioGroup({
    Key? key,
    required this.groupValue,
    required this.onChanged,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        return InkWell(
          onTap: () => onChanged(item.value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Radio<T>(value: item.value, groupValue: groupValue, onChanged: onChanged),
                const SizedBox(width: 8),
                Expanded(child: Text(item.label)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

Future<FileTypeSelection?> showFileTypeDialog(BuildContext context) async {
  return showDialog<FileTypeSelection>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      MergeInputType selected = MergeInputType.path;
      final controller = TextEditingController();

      return StatefulBuilder(builder: (context, setState) {
        final isUrlSelected = selected == MergeInputType.url;
        final canAccept = selected != null &&
            (!isUrlSelected || controller.text.trim().isNotEmpty);

        return AlertDialog(
          title: const Text('File Type'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioGroup<MergeInputType>(
                  groupValue: selected,
                  onChanged: (v) => setState(() => selected = v!),
                  items: const [
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
              child: const Text('Accept'),
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
            ),
          ],
        );
      });
    },
  );
}
