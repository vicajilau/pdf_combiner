import 'package:flutter/foundation.dart';

void printInDebug(Object? object) {
  if (kDebugMode) {
    print(object);
  }
}
