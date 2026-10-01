part of 'turnstile_widget.dart';

/// Controls a [UniversalTurnstile] widget and exposes its current token.
///
/// Notifies listeners when [token] changes. Methods called while no widget is
/// attached are no-ops.
class TurnstileController extends ChangeNotifier {
  TurnstileEngine? _engine;
  String? _token;

  /// Last token received, or `null` before success / after expiry or reset.
  ///
  /// Tokens are single-use and valid for 300 seconds; send it to your server
  /// and validate with Cloudflare `siteverify`.
  String? get token => _token;

  /// Whether a widget is currently attached.
  bool get isAttached => _engine != null;

  /// Drops the current token and runs a new challenge.
  Future<void> reset() async {
    _setToken(null);
    await _engine?.reset();
  }

  /// Runs the challenge when the widget uses [TurnstileExecution.execute].
  Future<void> execute() async => _engine?.execute();

  /// Whether the current token has expired (`true` when detached).
  Future<bool> isExpired() async => await _engine?.isExpired() ?? true;

  void _attach(TurnstileEngine engine) => _engine = engine;

  void _detach(TurnstileEngine engine) {
    if (identical(_engine, engine)) _engine = null;
  }

  void _setToken(String? token) {
    if (_token == token) return;
    _token = token;
    notifyListeners();
  }
}
