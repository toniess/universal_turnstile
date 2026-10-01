import 'package:flutter_test/flutter_test.dart';
import 'package:universal_turnstile/src/bridge/turnstile_html.dart';
import 'package:universal_turnstile/universal_turnstile.dart';

void main() {
  final html = buildTurnstileHtml(
    siteKey: '1x00000000000000000000AA',
    options: const TurnstileOptions(theme: TurnstileTheme.dark),
    postMessage: 'Bridge.postMessage',
  );

  test('loads the explicit-render script with the onload hook', () {
    expect(html, contains('$turnstileScriptUrl&onload=utOnLoad'));
  });

  test('embeds sitekey and options as JSON', () {
    expect(html, contains('"sitekey":"1x00000000000000000000AA"'));
    expect(html, contains('"theme":"dark"'));
  });

  test('routes messages through the engine bridge', () {
    expect(html, contains('Bridge.postMessage(JSON.stringify('));
  });

  test('wires every callback', () {
    for (final event in [
      'success',
      'error',
      'expired',
      'timeout',
      'beforeInteractive',
      'afterInteractive',
      'unsupported',
      'ready',
      'resize',
      'scriptError',
    ]) {
      expect(html, contains("utPost('$event'"), reason: event);
    }
  });
}
