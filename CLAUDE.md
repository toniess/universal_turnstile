# universal_turnstile — правила для Claude

Публичный Flutter-пакет для pub.dev: виджет Cloudflare Turnstile на всех 6
платформах. Общение — на русском; код, комментарии, коммиты, README и
CHANGELOG — на английском (аудитория pub.dev). ТЗ — [doc/SPEC.md](doc/SPEC.md),
источник истины: решение меняется → сначала SPEC, потом код.

## Жёсткие правила

1. **Движки**: Android/iOS/macOS — только официальный `webview_flutter`.
   Desktop — только платформенные пакеты (`*_windows`, `*_linux`), **никогда**
   зонтичные `webview_all` / `zikzak_inappwebview` / `flutter_inappwebview`:
   их нативный код попадёт в мобильные сборки.
2. **Web не импортирует `webview_flutter`** — выбор движка через
   `engine_factory.dart` (conditional export), ОС — в рантайме.
3. **Публичный API** — только то, что экспортирует
   `lib/universal_turnstile.dart`. События, движки, HTML — в `src/`, наружу
   не выставлять без записи в SPEC §4. Ломающие изменения — запись в CHANGELOG.
4. **Зависимости** — `^`-диапазоны, без пинов; новая зависимость — обоснование
   в SPEC. Своего нативного кода нет.
5. **Протокол моста** (SPEC §6) меняется синхронно в `turnstile_html.dart`,
   `turnstile_event.dart` и тестах; неизвестные события игнорируются.
6. **Секретный ключ** Cloudflare в пакете и example не появляется никогда.
7. Все публичные члены — с dartdoc (`public_member_api_docs`).

## Команды

```bash
fvm flutter pub get && (cd example && fvm flutter pub get)
fvm dart format .
fvm flutter analyze            # + cd example && fvm flutter analyze
fvm flutter test
cd example && fvm flutter run -d macos
fvm dart pub publish --dry-run
```

Перед коммитом: format, analyze (пакет и example), test — чисто.
Коммиты — Conventional Commits на английском (`feat:`, `fix:`, `docs:`, `chore:`).
