import 'dart:async';

import 'package:flutter/widgets.dart';

import 'bridge/turnstile_event.dart';
import 'engine/engine_factory.dart';
import 'engine/turnstile_engine.dart';
import 'turnstile_error.dart';
import 'turnstile_options.dart';

part 'turnstile_controller.dart';

/// Cloudflare Turnstile widget.
///
/// ```dart
/// UniversalTurnstile(
///   siteKey: '1x00000000000000000000AA',
///   baseUrl: Uri.parse('https://example.com'),
///   onToken: (token) => sendToServer(token),
/// )
/// ```
class UniversalTurnstile extends StatefulWidget {
  /// Creates the widget.
  const UniversalTurnstile({
    super.key,
    required this.siteKey,
    required this.baseUrl,
    this.options = const TurnstileOptions(),
    this.controller,
    this.onToken,
    this.onError,
    this.onExpired,
    this.onTimeout,
    this.onInteractive,
  });

  /// Sitekey from the Cloudflare dashboard.
  final String siteKey;

  /// Origin the widget is loaded from in webview engines. Its host must be in
  /// the widget's hostname allowlist, otherwise Cloudflare fails with
  /// `110200`. Ignored on the web, where the real page origin is used.
  final Uri baseUrl;

  /// Render options.
  final TurnstileOptions options;

  /// Optional controller for reset / execute and token access.
  final TurnstileController? controller;

  /// Called with a fresh token after a passed challenge.
  final ValueChanged<String>? onToken;

  /// Called on any widget or challenge error.
  final ValueChanged<TurnstileError>? onError;

  /// Called when the token expires.
  final VoidCallback? onExpired;

  /// Called when the interactive challenge times out.
  final VoidCallback? onTimeout;

  /// Called with `true` when user interaction is required and with `false`
  /// when it is done — e.g. to expand a collapsed container.
  final ValueChanged<bool>? onInteractive;

  @override
  State<UniversalTurnstile> createState() => _UniversalTurnstileState();
}

class _UniversalTurnstileState extends State<UniversalTurnstile> {
  late TurnstileEngine _engine;
  StreamSubscription<TurnstileEvent>? _subscription;
  Size? _contentSize;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(UniversalTurnstile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(_engine);
      widget.controller?._attach(_engine);
    }
    if (oldWidget.siteKey != widget.siteKey ||
        oldWidget.baseUrl != widget.baseUrl ||
        oldWidget.options != widget.options) {
      _stop();
      _contentSize = null;
      _start();
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _start() {
    _engine = (debugTurnstileEngineFactory ?? createTurnstileEngine)();
    _subscription = _engine.events.listen(_onEvent);
    widget.controller?._attach(_engine);
    unawaited(
      _engine.load(
        siteKey: widget.siteKey,
        options: widget.options,
        baseUrl: widget.baseUrl,
      ),
    );
  }

  void _stop() {
    widget.controller?._detach(_engine);
    unawaited(_subscription?.cancel());
    _engine.dispose();
  }

  void _onEvent(TurnstileEvent event) {
    switch (event) {
      case TurnstileReady():
        break;
      case TurnstileSuccess(:final token):
        widget.controller?._setToken(token);
        widget.onToken?.call(token);
      case TurnstileFailure(:final error):
        widget.controller?._setToken(null);
        widget.onError?.call(error);
      case TurnstileExpired():
        widget.controller?._setToken(null);
        widget.onExpired?.call();
      case TurnstileTimeout():
        widget.onTimeout?.call();
      case TurnstileInteractive(:final started):
        widget.onInteractive?.call(started);
      case TurnstileResized(:final size):
        if (mounted && size != _contentSize) {
          setState(() => _contentSize = size);
        }
    }
  }

  /// Size before the page reports its own, per Cloudflare docs.
  Size get _initialSize => switch (widget.options.size) {
    _ when widget.options.appearance != TurnstileAppearance.always => Size.zero,
    TurnstileSize.normal => const Size(300, 65),
    TurnstileSize.flexible => const Size(double.infinity, 65),
    TurnstileSize.compact => const Size(150, 140),
  };

  @override
  Widget build(BuildContext context) {
    final size = _contentSize ?? _initialSize;
    return SizedBox(
      width: widget.options.size == TurnstileSize.flexible
          ? double.infinity
          : size.width,
      height: size.height,
      child: _engine.build(context),
    );
  }
}
