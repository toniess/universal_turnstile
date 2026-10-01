# universal_turnstile

> **Work in progress — not published yet.** Android, iOS and macOS are being
> brought up first; Windows, Linux and Web follow. See [doc/SPEC.md](doc/SPEC.md).

[Cloudflare Turnstile](https://developers.cloudflare.com/turnstile/) for every
Flutter platform, using the official `webview_flutter` wherever it exists.

| Platform | Engine | Status |
|---|---|---|
| Android | `webview_flutter` (Android System WebView) | in progress |
| iOS | `webview_flutter` (WKWebView) | in progress |
| macOS | `webview_flutter` (WKWebView) | in progress |
| Windows | WebView2 | planned |
| Linux | WebKitGTK | planned |
| Web | native JS, no webview | planned |

Desktop engines are pulled in as platform-only packages, so mobile builds
never ship their native code.

## Usage

```dart
UniversalTurnstile(
  siteKey: 'your-sitekey',
  // Its host must be in the widget's hostname allowlist in the dashboard.
  baseUrl: Uri.parse('https://your-domain.com'),
  options: const TurnstileOptions(theme: TurnstileTheme.dark),
  onToken: (token) => sendToServer(token),
  onError: (error) => debugPrint('$error'),
)
```

Validate tokens on your server with
[`siteverify`](https://developers.cloudflare.com/turnstile/get-started/server-side-validation/).
Never put the secret key into the app.

## License

MIT
