import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:universal_turnstile/src/bridge/turnstile_event.dart';
import 'package:universal_turnstile/src/engine/turnstile_engine.dart';
import 'package:universal_turnstile/universal_turnstile.dart';

/// Records calls and lets tests push page events.
class FakeTurnstileEngine implements TurnstileEngine {
  final _events = StreamController<TurnstileEvent>.broadcast(sync: true);

  final loads = <({String siteKey, TurnstileOptions options, Uri baseUrl})>[];
  int resetCalls = 0;
  int executeCalls = 0;
  bool disposed = false;

  void emit(TurnstileEvent event) => _events.add(event);

  @override
  Stream<TurnstileEvent> get events => _events.stream;

  @override
  Future<void> load({
    required String siteKey,
    required TurnstileOptions options,
    required Uri baseUrl,
  }) async => loads.add((siteKey: siteKey, options: options, baseUrl: baseUrl));

  @override
  Future<void> reset() async => resetCalls++;

  @override
  Future<void> execute() async => executeCalls++;

  @override
  Future<String?> getResponse() async => null;

  @override
  Future<bool> isExpired() async => false;

  @override
  Widget build(BuildContext context) => const SizedBox.expand();

  @override
  void dispose() {
    disposed = true;
    unawaited(_events.close());
  }
}
