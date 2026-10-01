import 'package:flutter/foundation.dart';

import 'turnstile_engine.dart';
import 'unsupported_engine.dart';
import 'webview_flutter_engine.dart';

/// Picks the engine for the current non-web platform.
TurnstileEngine createTurnstileEngine() => switch (defaultTargetPlatform) {
  TargetPlatform.android ||
  TargetPlatform.iOS ||
  TargetPlatform.macOS => WebViewFlutterEngine(),
  // TODO(M3): desktop engine, chosen in the M2 spike (webview_all vs zikzak).
  TargetPlatform.windows || TargetPlatform.linux => UnsupportedTurnstileEngine(
    defaultTargetPlatform.name,
  ),
  TargetPlatform.fuchsia => UnsupportedTurnstileEngine('fuchsia'),
};
