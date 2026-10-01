import 'package:flutter/widgets.dart';

import '../bridge/turnstile_event.dart';
import '../turnstile_options.dart';

/// Rendering backend for one platform family.
///
/// Implementations:
/// - [WebViewFlutterEngine] — Android, iOS, macOS (official webview_flutter);
/// - desktop engine — Windows, Linux (doc/SPEC.md, M2–M3);
/// - web engine — browser, no webview (doc/SPEC.md, M4).
///
/// One engine instance serves one widget and is disposed with it.
abstract interface class TurnstileEngine {
  /// Events coming from the page. Broadcast, closed on [dispose].
  Stream<TurnstileEvent> get events;

  /// Loads and renders the widget. [baseUrl] becomes the page origin and must
  /// be in the widget's hostname allowlist in the Cloudflare dashboard.
  Future<void> load({
    required String siteKey,
    required TurnstileOptions options,
    required Uri baseUrl,
  });

  /// `turnstile.reset` — drops the token and runs a new challenge.
  Future<void> reset();

  /// `turnstile.execute` — runs the challenge when
  /// [TurnstileExecution.execute] is used.
  Future<void> execute();

  /// Current token or `null`.
  Future<String?> getResponse();

  /// Whether the current token has expired.
  Future<bool> isExpired();

  /// Platform view hosting the page.
  Widget build(BuildContext context);

  /// Releases resources.
  void dispose();
}

/// Replaces the platform engine; for tests only, not exported. Reset to
/// `null` in `tearDown`.
TurnstileEngine Function()? debugTurnstileEngineFactory;
