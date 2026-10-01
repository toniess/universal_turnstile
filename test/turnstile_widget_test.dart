import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_turnstile/src/bridge/turnstile_event.dart';
import 'package:universal_turnstile/src/engine/turnstile_engine.dart';
import 'package:universal_turnstile/universal_turnstile.dart';

import 'fake_turnstile_engine.dart';

void main() {
  late List<FakeTurnstileEngine> engines;

  setUp(() {
    engines = [];
    debugTurnstileEngineFactory = () {
      final engine = FakeTurnstileEngine();
      engines.add(engine);
      return engine;
    };
  });

  tearDown(() => debugTurnstileEngineFactory = null);

  final baseUrl = Uri.parse('https://example.com');

  Widget host({
    TurnstileOptions options = const TurnstileOptions(),
    TurnstileController? controller,
    ValueChanged<String>? onToken,
    ValueChanged<TurnstileError>? onError,
    VoidCallback? onExpired,
  }) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: UniversalTurnstile(
        siteKey: 'key',
        baseUrl: baseUrl,
        options: options,
        controller: controller,
        onToken: onToken,
        onError: onError,
        onExpired: onExpired,
      ),
    ),
  );

  testWidgets('loads the engine with sitekey, options and baseUrl', (
    tester,
  ) async {
    const options = TurnstileOptions(theme: TurnstileTheme.dark);
    await tester.pumpWidget(host(options: options));

    expect(engines.single.loads.single, (
      siteKey: 'key',
      options: options,
      baseUrl: baseUrl,
    ));
  });

  testWidgets('token flows to callback and controller, cleared on expiry', (
    tester,
  ) async {
    final controller = TurnstileController();
    final tokens = <String>[];
    var expired = 0;
    await tester.pumpWidget(
      host(
        controller: controller,
        onToken: tokens.add,
        onExpired: () => expired++,
      ),
    );

    engines.single.emit(const TurnstileSuccess('tok'));
    expect(tokens, ['tok']);
    expect(controller.token, 'tok');

    engines.single.emit(const TurnstileExpired());
    expect(expired, 1);
    expect(controller.token, isNull);
  });

  testWidgets('errors are reported', (tester) async {
    final errors = <TurnstileError>[];
    await tester.pumpWidget(host(onError: errors.add));

    engines.single.emit(const TurnstileFailure(TurnstileError('300010')));
    expect(errors, [const TurnstileError('300010')]);
  });

  testWidgets('controller drives the attached engine', (tester) async {
    final controller = TurnstileController();
    await tester.pumpWidget(host(controller: controller));
    engines.single.emit(const TurnstileSuccess('tok'));

    await controller.reset();
    await controller.execute();

    expect(engines.single.resetCalls, 1);
    expect(engines.single.executeCalls, 1);
    expect(controller.token, isNull);
  });

  testWidgets('initial size follows options, then the page size', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    expect(
      tester.getSize(find.byType(UniversalTurnstile)),
      const Size(300, 65),
    );

    engines.single.emit(const TurnstileResized(Size(300, 70)));
    await tester.pump();
    expect(
      tester.getSize(find.byType(UniversalTurnstile)),
      const Size(300, 70),
    );
  });

  testWidgets('collapsed until shown when appearance is not always', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        options: const TurnstileOptions(
          appearance: TurnstileAppearance.interactionOnly,
        ),
      ),
    );
    expect(tester.getSize(find.byType(UniversalTurnstile)), Size.zero);
  });

  testWidgets('changing options reloads with a fresh engine', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpWidget(
      host(options: const TurnstileOptions(theme: TurnstileTheme.light)),
    );

    expect(engines, hasLength(2));
    expect(engines.first.disposed, isTrue);
    expect(engines.last.loads.single.options.theme, TurnstileTheme.light);
  });

  testWidgets('equal options do not reload', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpWidget(host(options: TurnstileOptions()));

    expect(engines, hasLength(1));
  });

  testWidgets('controller detaches on dispose', (tester) async {
    final controller = TurnstileController();
    await tester.pumpWidget(host(controller: controller));
    expect(controller.isAttached, isTrue);

    await tester.pumpWidget(const SizedBox());
    expect(controller.isAttached, isFalse);
    expect(engines.single.disposed, isTrue);
  });
}
