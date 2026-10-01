import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../bridge/turnstile_event.dart';
import '../bridge/turnstile_html.dart';
import '../turnstile_options.dart';
import 'turnstile_engine.dart';

const _channelName = 'UniversalTurnstile';

/// Engine on top of the official webview_flutter (Android, iOS, macOS).
class WebViewFlutterEngine implements TurnstileEngine {
  /// Creates the engine and its webview controller.
  WebViewFlutterEngine() : _controller = WebViewController() {
    unawaited(_controller.setJavaScriptMode(JavaScriptMode.unrestricted));
    // TODO(M1): check transparency on macOS — the WKWebView implementation
    // configures it through UIKit-only APIs.
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      unawaited(_controller.setBackgroundColor(const Color(0x00000000)));
    }
    unawaited(
      _controller.addJavaScriptChannel(
        _channelName,
        onMessageReceived: (message) {
          final event = TurnstileEvent.tryParse(message.message);
          if (event != null && !_events.isClosed) _events.add(event);
        },
      ),
    );
  }

  final WebViewController _controller;
  final _events = StreamController<TurnstileEvent>.broadcast();

  @override
  Stream<TurnstileEvent> get events => _events.stream;

  @override
  Future<void> load({
    required String siteKey,
    required TurnstileOptions options,
    required Uri baseUrl,
  }) => _controller.loadHtmlString(
    buildTurnstileHtml(
      siteKey: siteKey,
      options: options,
      postMessage: '$_channelName.postMessage',
    ),
    baseUrl: baseUrl.toString(),
  );

  @override
  Future<void> reset() => _controller.runJavaScript('ut.reset()');

  @override
  Future<void> execute() => _controller.runJavaScript('ut.execute()');

  @override
  Future<String?> getResponse() async {
    final result = await _controller.runJavaScriptReturningResult(
      'ut.getResponse()',
    );
    // TODO(M1): platforms differ in how strings come back (quoted JSON on
    // Android, raw on iOS); normalize and cover with an integration test.
    return switch (result) {
      final String s when s.isNotEmpty && s != 'null' => _unquote(s),
      _ => null,
    };
  }

  @override
  Future<bool> isExpired() async {
    final result = await _controller.runJavaScriptReturningResult(
      'ut.isExpired()',
    );
    return result == true || result == 'true' || result == 1;
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);

  @override
  void dispose() => unawaited(_events.close());

  static String _unquote(String s) =>
      s.length >= 2 && s.startsWith('"') && s.endsWith('"')
      ? s.substring(1, s.length - 1)
      : s;
}
