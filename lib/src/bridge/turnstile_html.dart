import 'dart:convert';

import '../turnstile_options.dart';

/// Turnstile script with explicit rendering.
const turnstileScriptUrl =
    'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit';

/// Builds the page hosted by webview engines.
///
/// [postMessage] is a JS expression that receives a single string argument
/// and delivers it to Dart, e.g. `UniversalTurnstile.postMessage` for a
/// webview_flutter JavaScript channel. Every engine provides its own.
///
/// The page exposes `window.ut` with `reset()`, `remove()`, `execute()`,
/// `getResponse()` and `isExpired()` for the controller.
String buildTurnstileHtml({
  required String siteKey,
  required TurnstileOptions options,
  required String postMessage,
}) {
  final params = jsonEncode({'sitekey': siteKey, ...options.toRenderParams()});

  return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<style>
  html, body { margin: 0; padding: 0; background: transparent; overflow: hidden; }
  #ut-root { display: inline-block; }
</style>
<script>
  function utPost(event, data) {
    $postMessage(JSON.stringify({ event: event, data: data === undefined ? null : data }));
  }
  var utWidgetId = null;
  window.ut = {
    reset: function () { if (utWidgetId !== null) turnstile.reset(utWidgetId); },
    remove: function () { if (utWidgetId !== null) { turnstile.remove(utWidgetId); utWidgetId = null; } },
    execute: function () { if (utWidgetId !== null) turnstile.execute(utWidgetId); },
    getResponse: function () { return utWidgetId === null ? null : (turnstile.getResponse(utWidgetId) || null); },
    isExpired: function () { return utWidgetId === null ? true : turnstile.isExpired(utWidgetId); }
  };
  function utOnLoad() {
    var params = $params;
    params.callback = function (token) { utPost('success', token); };
    params['error-callback'] = function (code) { utPost('error', String(code)); return true; };
    params['expired-callback'] = function () { utPost('expired'); };
    params['timeout-callback'] = function () { utPost('timeout'); };
    params['before-interactive-callback'] = function () { utPost('beforeInteractive'); };
    params['after-interactive-callback'] = function () { utPost('afterInteractive'); };
    params['unsupported-callback'] = function () { utPost('unsupported'); };
    var root = document.getElementById('ut-root');
    utWidgetId = turnstile.render(root, params);
    utPost('ready', String(utWidgetId));
    if (window.ResizeObserver) {
      new ResizeObserver(function () {
        var r = root.getBoundingClientRect();
        utPost('resize', { width: r.width, height: r.height });
      }).observe(root);
    }
  }
  function utOnScriptError() { utPost('scriptError', '$turnstileScriptUrl'); }
</script>
<script src="$turnstileScriptUrl&onload=utOnLoad" async defer onerror="utOnScriptError()"></script>
</head>
<body><div id="ut-root"></div></body>
</html>
''';
}
