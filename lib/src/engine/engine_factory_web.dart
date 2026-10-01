import 'turnstile_engine.dart';
import 'unsupported_engine.dart';

/// Picks the engine for the web.
// TODO(M4): web engine — load api.js into the host page and render into an
// HtmlElementView via package:web, without a webview.
TurnstileEngine createTurnstileEngine() => UnsupportedTurnstileEngine('web');
