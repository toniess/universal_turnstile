// Web builds must not import webview_flutter, so the factory is split by
// conditional import.
export 'engine_factory_io.dart'
    if (dart.library.js_interop) 'engine_factory_web.dart';
