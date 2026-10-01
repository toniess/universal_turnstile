import 'package:flutter/material.dart';
import 'package:universal_turnstile/universal_turnstile.dart';

void main() => runApp(const ExampleApp());

/// Cloudflare test sitekeys — work on any hostname, no account needed.
/// https://developers.cloudflare.com/turnstile/troubleshooting/testing/
enum TestSiteKey {
  passVisible('1x00000000000000000000AA', 'Always passes (visible)'),
  failVisible('2x00000000000000000000AB', 'Always fails (visible)'),
  passInvisible('1x00000000000000000000BB', 'Always passes (invisible)'),
  failInvisible('2x00000000000000000000BB', 'Always fails (invisible)'),
  interactive('3x00000000000000000000FF', 'Forces interactive challenge');

  const TestSiteKey(this.key, this.label);

  final String key;
  final String label;
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'universal_turnstile',
    theme: ThemeData(colorSchemeSeed: Colors.orange),
    darkTheme: ThemeData(
      colorSchemeSeed: Colors.orange,
      brightness: Brightness.dark,
    ),
    home: const ExamplePage(),
  );
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  final _controller = TurnstileController();
  final _log = <String>[];
  var _siteKey = TestSiteKey.passVisible;
  var _theme = TurnstileTheme.auto;
  var _size = TurnstileSize.normal;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addLog(String line) => setState(() => _log.insert(0, line));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('universal_turnstile')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButton<TestSiteKey>(
          value: _siteKey,
          isExpanded: true,
          items: [
            for (final k in TestSiteKey.values)
              DropdownMenuItem(value: k, child: Text(k.label)),
          ],
          onChanged: (k) => setState(() => _siteKey = k!),
        ),
        SegmentedButton<TurnstileTheme>(
          segments: [
            for (final t in TurnstileTheme.values)
              ButtonSegment(value: t, label: Text(t.name)),
          ],
          selected: {_theme},
          onSelectionChanged: (s) => setState(() => _theme = s.single),
        ),
        const SizedBox(height: 8),
        SegmentedButton<TurnstileSize>(
          segments: [
            for (final s in TurnstileSize.values)
              ButtonSegment(value: s, label: Text(s.name)),
          ],
          selected: {_size},
          onSelectionChanged: (s) => setState(() => _size = s.single),
        ),
        const SizedBox(height: 16),
        Center(
          child: UniversalTurnstile(
            // Test keys accept any hostname; real keys need this host in the
            // widget's allowlist.
            siteKey: _siteKey.key,
            baseUrl: Uri.parse('https://example.com'),
            options: TurnstileOptions(theme: _theme, size: _size),
            controller: _controller,
            onToken: (t) => _addLog('token: ${t.substring(0, 16)}…'),
            onError: (e) => _addLog('error: $e'),
            onExpired: () => _addLog('expired'),
            onTimeout: () => _addLog('timeout'),
            onInteractive: (started) =>
                _addLog(started ? 'interactive: start' : 'interactive: end'),
          ),
        ),
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => Text(
            _controller.token == null ? 'No token' : 'Has token',
            textAlign: TextAlign.center,
          ),
        ),
        TextButton(onPressed: _controller.reset, child: const Text('Reset')),
        const Divider(),
        for (final line in _log) Text(line),
      ],
    ),
  );
}
