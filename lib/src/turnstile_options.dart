/// Widget color theme.
enum TurnstileTheme {
  /// Follows the system color scheme.
  auto('auto'),

  /// Light theme.
  light('light'),

  /// Dark theme.
  dark('dark');

  const TurnstileTheme(this.value);

  /// Value passed to `turnstile.render`.
  final String value;
}

/// Widget size.
enum TurnstileSize {
  /// 300x65.
  normal('normal'),

  /// Fills the available width (min 300), height 65.
  flexible('flexible'),

  /// 150x140.
  compact('compact');

  const TurnstileSize(this.value);

  /// Value passed to `turnstile.render`.
  final String value;
}

/// When the widget becomes visible.
enum TurnstileAppearance {
  /// Always visible.
  always('always'),

  /// Visible only after the challenge starts executing.
  execute('execute'),

  /// Visible only when user interaction is required.
  interactionOnly('interaction-only');

  const TurnstileAppearance(this.value);

  /// Value passed to `turnstile.render`.
  final String value;
}

/// When the challenge runs.
enum TurnstileExecution {
  /// Right after render.
  render('render'),

  /// Only after [TurnstileController.execute] is called.
  execute('execute');

  const TurnstileExecution(this.value);

  /// Value passed to `turnstile.render`.
  final String value;
}

/// Automatic retry on failure.
enum TurnstileRetry {
  /// Retry automatically.
  auto('auto'),

  /// Never retry; the host app decides.
  never('never');

  const TurnstileRetry(this.value);

  /// Value passed to `turnstile.render`.
  final String value;
}

/// Behaviour when a token expires or an interactive challenge times out.
enum TurnstileRefresh {
  /// Refresh automatically.
  auto('auto'),

  /// Show a refresh button to the user.
  manual('manual'),

  /// Do nothing; the host app calls [TurnstileController.reset].
  never('never');

  const TurnstileRefresh(this.value);

  /// Value passed to `turnstile.render`.
  final String value;
}

/// Render parameters of the Turnstile widget.
///
/// Maps one-to-one onto the Cloudflare `turnstile.render` configuration,
/// see https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/.
class TurnstileOptions {
  /// Creates render options. Defaults match Cloudflare defaults.
  const TurnstileOptions({
    this.action,
    this.cData,
    this.theme = TurnstileTheme.auto,
    this.size = TurnstileSize.normal,
    this.language = 'auto',
    this.appearance = TurnstileAppearance.always,
    this.execution = TurnstileExecution.render,
    this.retry = TurnstileRetry.auto,
    this.retryInterval = const Duration(milliseconds: 8000),
    this.refreshExpired = TurnstileRefresh.auto,
    this.refreshTimeout = TurnstileRefresh.auto,
    this.feedbackEnabled = true,
  });

  /// Customer label for analytics, `[a-zA-Z0-9_-]{0,32}`.
  final String? action;

  /// Customer payload returned on validation, `[a-zA-Z0-9_-]{0,255}`.
  final String? cData;

  /// Color theme.
  final TurnstileTheme theme;

  /// Widget size.
  final TurnstileSize size;

  /// ISO 639-1 language (optionally with region), or `auto`.
  final String language;

  /// When the widget is visible.
  final TurnstileAppearance appearance;

  /// When the challenge runs.
  final TurnstileExecution execution;

  /// Automatic retry on failure.
  final TurnstileRetry retry;

  /// Delay between automatic retries. Cloudflare requires it to be below
  /// 15 minutes.
  final Duration retryInterval;

  /// Behaviour on token expiry.
  final TurnstileRefresh refreshExpired;

  /// Behaviour on interactive challenge timeout. `never` is not allowed by
  /// Cloudflare here and falls back to `auto`.
  final TurnstileRefresh refreshTimeout;

  /// Whether Cloudflare may ask for feedback on failure.
  final bool feedbackEnabled;

  @override
  bool operator ==(Object other) =>
      other is TurnstileOptions &&
      other.action == action &&
      other.cData == cData &&
      other.theme == theme &&
      other.size == size &&
      other.language == language &&
      other.appearance == appearance &&
      other.execution == execution &&
      other.retry == retry &&
      other.retryInterval == retryInterval &&
      other.refreshExpired == refreshExpired &&
      other.refreshTimeout == refreshTimeout &&
      other.feedbackEnabled == feedbackEnabled;

  @override
  int get hashCode => Object.hash(
    action,
    cData,
    theme,
    size,
    language,
    appearance,
    execution,
    retry,
    retryInterval,
    refreshExpired,
    refreshTimeout,
    feedbackEnabled,
  );

  /// Render config for `turnstile.render`, without the sitekey and callbacks.
  Map<String, Object> toRenderParams() => {
    'action': ?action,
    'cData': ?cData,
    'theme': theme.value,
    'size': size.value,
    'language': language,
    'appearance': appearance.value,
    'execution': execution.value,
    'retry': retry.value,
    'retry-interval': retryInterval.inMilliseconds,
    'refresh-expired': refreshExpired.value,
    'refresh-timeout': refreshTimeout == TurnstileRefresh.never
        ? TurnstileRefresh.auto.value
        : refreshTimeout.value,
    'feedback-enabled': feedbackEnabled,
  };
}
