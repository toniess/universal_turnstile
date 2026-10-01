import 'dart:async';

import 'package:flutter/widgets.dart';

import '../bridge/turnstile_event.dart';
import '../turnstile_error.dart';
import '../turnstile_options.dart';
import 'turnstile_engine.dart';

/// Placeholder for platforms without an engine yet: renders nothing and
/// reports [TurnstileError.unsupportedPlatform] on [load].
class UnsupportedTurnstileEngine implements TurnstileEngine {
  /// Creates the engine; [platform] goes into the error message.
  UnsupportedTurnstileEngine(this.platform);

  /// Name of the unsupported platform.
  final String platform;

  final _events = StreamController<TurnstileEvent>.broadcast();

  @override
  Stream<TurnstileEvent> get events => _events.stream;

  @override
  Future<void> load({
    required String siteKey,
    required TurnstileOptions options,
    required Uri baseUrl,
  }) async {
    // Delivered asynchronously so listeners attached after load() see it.
    scheduleMicrotask(() {
      if (_events.isClosed) return;
      _events.add(
        TurnstileFailure(
          TurnstileError(TurnstileError.unsupportedPlatform, platform),
        ),
      );
    });
  }

  @override
  Future<void> reset() async {}

  @override
  Future<void> execute() async {}

  @override
  Future<String?> getResponse() async => null;

  @override
  Future<bool> isExpired() async => true;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  @override
  void dispose() => unawaited(_events.close());
}
