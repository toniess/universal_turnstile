import 'package:flutter_test/flutter_test.dart';
import 'package:universal_turnstile/universal_turnstile.dart';

void main() {
  group('TurnstileOptions.toRenderParams', () {
    test('defaults match Cloudflare defaults', () {
      expect(const TurnstileOptions().toRenderParams(), {
        'theme': 'auto',
        'size': 'normal',
        'language': 'auto',
        'appearance': 'always',
        'execution': 'render',
        'retry': 'auto',
        'retry-interval': 8000,
        'refresh-expired': 'auto',
        'refresh-timeout': 'auto',
        'feedback-enabled': true,
      });
    });

    test('includes action and cData only when set', () {
      final params = const TurnstileOptions(
        action: 'login',
        cData: 'abc',
        appearance: TurnstileAppearance.interactionOnly,
      ).toRenderParams();

      expect(params['action'], 'login');
      expect(params['cData'], 'abc');
      expect(params['appearance'], 'interaction-only');
    });

    test('refreshTimeout never falls back to auto', () {
      final params = const TurnstileOptions(
        refreshTimeout: TurnstileRefresh.never,
      ).toRenderParams();

      expect(params['refresh-timeout'], 'auto');
    });
  });

  test('equal options are ==', () {
    expect(
      const TurnstileOptions(theme: TurnstileTheme.dark),
      TurnstileOptions(theme: TurnstileTheme.values.byName('dark')),
    );
    expect(
      const TurnstileOptions(theme: TurnstileTheme.dark),
      isNot(const TurnstileOptions()),
    );
  });
}
