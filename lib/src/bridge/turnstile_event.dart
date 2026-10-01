import 'dart:convert';
import 'dart:ui';

import '../turnstile_error.dart';

/// Message sent from the page to Dart over the JS bridge.
///
/// Wire format: `{"event": "<name>", "data": <payload>}` — see doc/SPEC.md,
/// section «JS-мост».
sealed class TurnstileEvent {
  const TurnstileEvent();

  /// Parses a raw bridge message. Returns `null` for malformed or unknown
  /// messages so a newer page never crashes an older Dart side.
  static TurnstileEvent? tryParse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, Object?>) return null;
    final data = decoded['data'];

    return switch (decoded['event']) {
      'ready' when data is String => TurnstileReady(data),
      'success' when data is String => TurnstileSuccess(data),
      'error' => TurnstileFailure(
        TurnstileError(data?.toString() ?? 'unknown'),
      ),
      'expired' => const TurnstileExpired(),
      'timeout' => const TurnstileTimeout(),
      'beforeInteractive' => const TurnstileInteractive(started: true),
      'afterInteractive' => const TurnstileInteractive(started: false),
      'unsupported' => const TurnstileFailure(
        TurnstileError(TurnstileError.unsupportedBrowser),
      ),
      'scriptError' => TurnstileFailure(
        TurnstileError(TurnstileError.scriptLoadFailed, data?.toString()),
      ),
      'resize' when data is Map<String, Object?> => switch ((
        data['width'],
        data['height'],
      )) {
        (final num w, final num h) => TurnstileResized(
          Size(w.toDouble(), h.toDouble()),
        ),
        _ => null,
      },
      _ => null,
    };
  }
}

/// Widget rendered; [widgetId] is the id returned by `turnstile.render`.
final class TurnstileReady extends TurnstileEvent {
  /// Creates the event.
  const TurnstileReady(this.widgetId);

  /// Id of the rendered widget.
  final String widgetId;
}

/// Challenge passed.
final class TurnstileSuccess extends TurnstileEvent {
  /// Creates the event.
  const TurnstileSuccess(this.token);

  /// Single-use token, valid for 300 s. Validate it on the server.
  final String token;
}

/// Challenge or widget failed.
final class TurnstileFailure extends TurnstileEvent {
  /// Creates the event.
  const TurnstileFailure(this.error);

  /// The error.
  final TurnstileError error;
}

/// Token expired.
final class TurnstileExpired extends TurnstileEvent {
  /// Creates the event.
  const TurnstileExpired();
}

/// Interactive challenge timed out.
final class TurnstileTimeout extends TurnstileEvent {
  /// Creates the event.
  const TurnstileTimeout();
}

/// Interactive challenge started ([started] is `true`) or finished.
final class TurnstileInteractive extends TurnstileEvent {
  /// Creates the event.
  const TurnstileInteractive({required this.started});

  /// `true` before, `false` after the interactive step.
  final bool started;
}

/// Rendered content size changed.
final class TurnstileResized extends TurnstileEvent {
  /// Creates the event.
  const TurnstileResized(this.size);

  /// New content size in logical pixels.
  final Size size;
}
