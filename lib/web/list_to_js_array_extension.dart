import 'dart:js_interop';

/// **Extension to convert `List<String>` to `JSArray<JSString>`**
///
/// This extension adds a method to `List<String>` that converts the list of
/// Dart strings to a `JSArray<JSString>`. Each string in the Dart list is
/// converted to a JS string using the `toJS` method and then the list is
/// transformed into a JavaScript array.
extension ListToJSArray on List<String> {
  /// Converts each String to JSString and maps them into a JSArray
  JSArray<JSString> toJSArray() {
    return map((e) => e.toJS).toList().toJS;
  }
}

/// **Extension to convert `JSArray<JSString>` to `List<String>`**
///
/// This extension adds a method to `JSArray<JSString>` that converts the
/// JavaScript array of JS strings back into a Dart list of regular strings.
/// It uses `toDart` to convert each JSString into a Dart String.
extension JSArrayToList on JSArray<JSString> {
  /// Converts each JSString in the JSArray to a Dart String and collects them into a List
  List<String> toList() {
    return toDart.map((jsStr) => jsStr.toDart).toList();
  }
}
