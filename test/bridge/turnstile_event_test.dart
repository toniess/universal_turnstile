import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_turnstile/src/bridge/turnstile_event.dart';
import 'package:universal_turnstile/universal_turnstile.dart';

void main() {
  group('TurnstileEvent.tryParse', () {
    test('success carries the token', () {
      final event = TurnstileEvent.tryParse('{"event":"success","data":"tok"}');
      expect(
        event,
        isA<TurnstileSuccess>().having((e) => e.token, 'token', 'tok'),
      );
    });

    test('error carries the Cloudflare code', () {
      final event = TurnstileEvent.tryParse(
        '{"event":"error","data":"110200"}',
      );
      expect(
        event,
        isA<TurnstileFailure>().having(
          (e) => e.error,
          'error',
          const TurnstileError('110200'),
        ),
      );
      expect((event! as TurnstileFailure).error.isConfigurationError, isTrue);
    });

    test('unsupported and scriptError map to package codes', () {
      expect(
        (TurnstileEvent.tryParse('{"event":"unsupported","data":null}')!
                as TurnstileFailure)
            .error
            .code,
        TurnstileError.unsupportedBrowser,
      );
      expect(
        (TurnstileEvent.tryParse('{"event":"scriptError","data":"x"}')!
                as TurnstileFailure)
            .error
            .code,
        TurnstileError.scriptLoadFailed,
      );
    });

    test('resize carries the size', () {
      final event = TurnstileEvent.tryParse(
        '{"event":"resize","data":{"width":300,"height":65.5}}',
      );
      expect(
        event,
        isA<TurnstileResized>().having(
          (e) => e.size,
          'size',
          const Size(300, 65.5),
        ),
      );
    });

    test('interactive start and end', () {
      expect(
        TurnstileEvent.tryParse('{"event":"beforeInteractive","data":null}'),
        isA<TurnstileInteractive>().having((e) => e.started, 'started', true),
      );
      expect(
        TurnstileEvent.tryParse('{"event":"afterInteractive","data":null}'),
        isA<TurnstileInteractive>().having((e) => e.started, 'started', false),
      );
    });

    test('malformed or unknown messages are ignored', () {
      expect(TurnstileEvent.tryParse('not json'), isNull);
      expect(TurnstileEvent.tryParse('[1,2]'), isNull);
      expect(TurnstileEvent.tryParse('{"event":"future"}'), isNull);
      expect(TurnstileEvent.tryParse('{"event":"success","data":1}'), isNull);
      expect(TurnstileEvent.tryParse('{"event":"resize","data":{}}'), isNull);
    });
  });
}
