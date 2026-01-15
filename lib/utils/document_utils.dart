// Platform-specific implementations are exported only for plugin registration.
// These exports are hidden on Web to avoid dart:ffi and dart:io compatibility issues.
export 'document_utils_io.dart'
    if (dart.library.js_interop) 'document_utils_web.dart';
