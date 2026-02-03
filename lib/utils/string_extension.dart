import 'package:file_magic_number/file_magic_number.dart';

extension StringExtension on String? {
  FileMagicNumberType get stringToMagicType {
    final s = this ?? '';
    final segments = s.split('/').where((p) => p.isNotEmpty).toList();
    final lastSegment = segments.isEmpty ? '' : segments.last;
    final cleaned = lastSegment.split(RegExp(r'[?#]')).first;
    final extension = cleaned.contains('.')
        ? cleaned.substring(cleaned.lastIndexOf('.') + 1)
        : '';
    return FileMagicNumberType.values.firstWhere(
      (e) => e.name.toLowerCase() == extension.toLowerCase(),
      orElse: () => FileMagicNumberType.unknown,
    );
  }
}
