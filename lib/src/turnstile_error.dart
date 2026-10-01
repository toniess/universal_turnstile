/// Error reported by the Turnstile widget.
///
/// [code] is the Cloudflare error code (e.g. `110200` — unknown domain),
/// see https://developers.cloudflare.com/turnstile/troubleshooting/client-side-errors/error-codes/.
/// Codes produced by this package itself are prefixed with `ut_`.
class TurnstileError {
  /// Creates an error with a Cloudflare or package [code].
  const TurnstileError(this.code, [this.message]);

  /// Script failed to load (no network, blocked host).
  static const scriptLoadFailed = 'ut_script_load_failed';

  /// The platform has no supported engine.
  static const unsupportedPlatform = 'ut_unsupported_platform';

  /// Cloudflare reported the browser engine as unsupported.
  static const unsupportedBrowser = 'ut_unsupported_browser';

  /// Error code.
  final String code;

  /// Optional human-readable details.
  final String? message;

  /// Whether the code belongs to the configuration family (`110xxx`):
  /// wrong sitekey, domain not allowed, invalid parameters. Retrying won't help.
  bool get isConfigurationError => code.startsWith('110');

  @override
  String toString() =>
      'TurnstileError($code${message == null ? '' : ': $message'})';

  @override
  bool operator ==(Object other) =>
      other is TurnstileError && other.code == code && other.message == message;

  @override
  int get hashCode => Object.hash(code, message);
}
