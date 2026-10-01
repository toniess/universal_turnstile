# universal_turnstile — техническое задание

Статус: черновик v0.1 (2026-10-01). Это источник истины по скоупу и решениям.
Если решение меняется, сначала правим этот файл, потом код.

## 1. Цель

Flutter-пакет с виджетом [Cloudflare Turnstile](https://developers.cloudflare.com/turnstile/),
который работает на **всех шести платформах** Flutter (Android, iOS, macOS,
Windows, Linux, Web). На мобилках и macOS он использует **официальный**
`webview_flutter`, а на остальных платформах — лучший доступный движок, не
затягивая чужой нативный код туда, где он не нужен.

## 2. Почему не существующие пакеты

Данные pub.dev на 2026-10-01:

| Пакет | Движок | Платформы | Проблема |
|---|---|---|---|
| `cloudflare_turnstile` 3.8.1 | `flutter_inappwebview ^6.1.5` | android, ios, macos, windows, web | нет Linux; на мобилках тянет inappwebview вместо официального движка |
| `turnstile_pro` 0.1.1 | `webview_flutter` | android, ios, macos | нет Windows, Linux, Web |
| `flutter_turnstile` 1.2.0 | `webview_flutter` 4.8 | android, ios, (web) | заброшен |
| `dynamic_sdk_captcha` 2.0.0-beta | — | все шесть только формально | нет движка, привязан к Dynamic |

Пакета, который реально рендерит Turnstile на Linux, нет.

## 3. Платформы и движки

| Платформа | Движок | Пакет | Статус |
|---|---|---|---|
| Android | Android System WebView | `webview_flutter` (→ `webview_flutter_android`) | M1 |
| iOS | WKWebView | `webview_flutter` (→ `webview_flutter_wkwebview`) | M1 |
| macOS | WKWebView | `webview_flutter` (→ `webview_flutter_wkwebview`) | M1 |
| Windows | WebView2 | `webview_all_windows` **или** `zikzak_inappwebview_windows` | M2 спайк → M3 |
| Linux | WebKitGTK | `webview_all_linux` **или** `zikzak_inappwebview_linux` | M2 спайк → M3 |
| Web | браузер, без webview | `package:web` + `HtmlElementView` | M4 |

### Ключевое правило зависимостей

На desktop подключаем **только платформенные реализации** (`*_windows`,
`*_linux`), а не зонтичные пакеты (`webview_all`, `zikzak_inappwebview`).
Плагин регистрирует нативный код только на платформах из своего
`flutter.plugin.platforms`. Поэтому в сборке под Android/iOS не будет ни
строчки нативного кода desktop-движков.

Эту гарантию проверяем на CI: в собранном APK и iOS-приложении не должно
быть классов desktop-движков (см. §9).

## 4. Публичный API

Экспортируется только `package:universal_turnstile/universal_turnstile.dart`:

- `UniversalTurnstile` — виджет.
  - `siteKey` (обязательный).
  - `baseUrl` (обязательный, `Uri`) — origin страницы в webview. Хост должен
    быть в allowlist виджета в дашборде Cloudflare, иначе будет ошибка `110200`.
    На Web игнорируется, там используется реальный origin.
  - `options: TurnstileOptions`.
  - `controller: TurnstileController?`.
  - колбэки `onToken`, `onError`, `onExpired`, `onTimeout`, `onInteractive`.
- `TurnstileOptions` — один к одному отображается на конфиг `turnstile.render`:
  `action`, `cData`, `theme`, `size`, `language`, `appearance`, `execution`,
  `retry`, `retryInterval`, `refreshExpired`, `refreshTimeout`,
  `feedbackEnabled`. Значения по умолчанию совпадают с дефолтами Cloudflare.
  Есть `==`: при изменении опций виджет перезагружается, при равных — нет.
- `TurnstileController` (`ChangeNotifier`) — `token`, `isAttached`, `reset()`,
  `execute()`, `isExpired()`.
- `TurnstileError` — `code` (код Cloudflare или собственный с префиксом
  `ut_`), `message`, `isConfigurationError` (семейство `110xxx`).

Не экспортируются: события моста, движки, HTML-шаблон. Расширение
пользовательскими движками сознательно отложено до 1.0, чтобы не фиксировать
интерфейс `TurnstileEngine` раньше времени.

### Поведение размера

До первого `resize` со страницы размер берётся из документации Cloudflare:
normal — 300×65, compact — 150×140, flexible — вся ширина × 65. Если
`appearance != always`, начальный размер 0×0. После этого размер задаёт
страница через `ResizeObserver`.

## 5. Архитектура

```
lib/
  universal_turnstile.dart        # баррель (только публичный API)
  src/
    turnstile_widget.dart         # UniversalTurnstile + part controller
    turnstile_controller.dart
    turnstile_options.dart
    turnstile_error.dart
    bridge/
      turnstile_event.dart        # sealed-события + парсер протокола
      turnstile_html.dart         # HTML-страница для webview-движков
    engine/
      turnstile_engine.dart       # интерфейс движка + тестовый хук
      engine_factory.dart         # conditional export io/web
      engine_factory_io.dart      # выбор по defaultTargetPlatform
      engine_factory_web.dart
      webview_flutter_engine.dart # android/ios/macos
      unsupported_engine.dart     # заглушка: отдаёт ut_unsupported_platform
      (desktop_engine.dart)       # M3
      (web_engine.dart)           # M4
example/                          # демо на всех 6 платформах, тестовые ключи
test/                             # unit + widget на FakeTurnstileEngine
```

Выбор движка: web/не-web — через conditional import (`dart.library.js_interop`),
чтобы web-сборка не импортировала `webview_flutter`. Конкретная ОС —
в рантайме по `defaultTargetPlatform`.

## 6. JS-мост

Все webview-движки грузят одну и ту же страницу из `buildTurnstileHtml`.
Отличается только выражение `postMessage`, которое движок подставляет в
шаблон. Например, для `webview_flutter` это
`UniversalTurnstile.postMessage` (JavaScript channel).

Формат сообщения страница → Dart: `{"event": "<name>", "data": <payload>}`.

| event | data | Источник |
|---|---|---|
| `ready` | widgetId (string) | после `turnstile.render` |
| `success` | token (string) | `callback` |
| `error` | код Cloudflare (string) | `error-callback` |
| `expired` | null | `expired-callback` |
| `timeout` | null | `timeout-callback` |
| `beforeInteractive` / `afterInteractive` | null | соответствующие колбэки |
| `unsupported` | null | `unsupported-callback` |
| `scriptError` | url | `onerror` у `<script>` |
| `resize` | `{width, height}` | `ResizeObserver` на контейнере |

Неизвестные или битые сообщения игнорируются (`tryParse` → `null`). Так
новая страница не роняет старый Dart-код.

Dart → страница: `window.ut.reset() / remove() / execute() / getResponse() /
isExpired()`.

## 7. Функциональные требования

1. Рендер виджета с любым набором `TurnstileOptions` на всех платформах.
2. Токен доставляется в `onToken` и `controller.token`. При expire, error и
   reset токен сбрасывается в `null`.
3. `controller.reset()` запускает новый челлендж, `execute()` работает при
   `execution: execute`.
4. Ошибки Cloudflare пробрасываются с исходным кодом. Свои ошибки:
   `ut_script_load_failed`, `ut_unsupported_platform`, `ut_unsupported_browser`.
5. Прозрачный фон: виджет не рисует белый прямоугольник в тёмной теме.
6. Внешние ссылки из виджета (Privacy, Terms, «Need help?») открываются не
   внутри webview. Как именно — решить в M1: `url_launcher` или колбэк
   `onOpenUrl`, чтобы не тащить лишнюю зависимость.
7. Изменение `siteKey`, `baseUrl` или `options` перезагружает виджет, равные
   значения — нет.
8. Отключение controller и освобождение движка при dispose.

## 8. Нефункциональные требования

- pub.dev: 160/160 pub points, все 6 platform-бейджей, WASM-ready.
- Своего нативного кода нет, пакет на чистом Dart.
- Зависимости через `^`-диапазоны, без пинов.
- Минимальные версии: Dart `^3.10.0`, Flutter `>=3.38.0` (берём у
  `webview_flutter` 4.14).
- Документация: dartdoc для всего публичного API, README с таблицей платформ,
  разделом про hostname/`baseUrl` и требованиями desktop (WebView2,
  webkit2gtk-4.1).
- Безопасность: пакет только получает токен. Проверка через `siteverify`
  делается на сервере, секретный ключ в клиенте не используется и в примерах
  не упоминается.

## 9. Тестирование

- **Unit**: опции → render-параметры, парсинг событий, HTML-шаблон.
- **Widget**: `UniversalTurnstile` на `FakeTurnstileEngine` (хук
  `debugTurnstileEngineFactory`): токен, ошибки, размер, перезагрузка,
  controller.
- **Integration** (`example/integration_test`, M1+): на каждой платформе с
  тестовыми ключами Cloudflare:
  - `1x00000000000000000000AA` — всегда проходит (видимый);
  - `2x00000000000000000000AB` — всегда падает (видимый);
  - `1x00000000000000000000BB` / `2x00000000000000000000BB` — то же,
    невидимый;
  - `3x00000000000000000000FF` — форсирует интерактивный челлендж.
- **Проверка изоляции движков** (M3): в собранном APK и iOS-приложении
  example нет классов `webview_all`/`zikzak`.
- **CI** (GitHub Actions): format, analyze, test, `pana`,
  `dart pub publish --dry-run`; сборка example на ubuntu (linux, web, android),
  windows, macos (macos, ios без подписи).

## 10. Этапы

| | Этап | Результат |
|---|---|---|
| M0 | Каркас | ✅ структура, публичный API, протокол, HTML, unit/widget-тесты, example, ТЗ |
| M1 | Android / iOS / macOS | движок `webview_flutter` проверен вживую; прозрачность на macOS; нормализация `runJavaScriptReturningResult`; внешние ссылки; integration-тесты |
| M2 | Спайк desktop | на Windows и Linux проверить `webview_all_*` и `zikzak_inappwebview_*`: `loadHtmlString`/`loadData` с `baseUrl`, JS-канал, прозрачность, размер бинаря, живость репозитория. Решение записать в §11 |
| M3 | Windows / Linux | desktop-движок + проверка изоляции на мобилках |
| M4 | Web | движок на `package:web`: один раз грузим `api.js`, рендерим в `HtmlElementView`, несколько виджетов на странице |
| M5 | Публикация 0.1.0 | README, dartdoc, CHANGELOG, `pana` 160/160, CI зелёный, `pub publish` |

## 11. Решения и открытые вопросы

Решено:
- Имя пакета — `universal_turnstile` (на pub.dev было свободно на 2026-10-01).
- Публикация — личная, репозиторий `github.com/toniess/universal_turnstile`.
- Лицензия — MIT. Если переносим код из `cloudflare_turnstile` или
  `turnstile_pro` (оба MIT), их copyright добавляем в LICENSE.

Открыто:
1. **Desktop-движок** (M2): у `webview_all` API совместим с `webview_flutter`,
   один мейнтейнер, Linux на webkit2gtk-4.1. У `zikzak_inappwebview` API
   inappwebview, тоже один мейнтейнер, Windows через `webview_windows`.
2. **Регистрация платформенных пакетов без зонтика**: оба кандидата объявлены
   как `implements: <umbrella>`. Нужно проверить, что flutter_tools
   регистрирует `dartPluginClass` транзитивной реализации, если зонтика нет
   в графе. Запасной вариант — вручную вызывать `registerWith()` перед
   созданием движка.
3. **Hostname**: допускает ли Cloudflare origin от `loadHtmlString(baseUrl:)`
   на каждом движке. Особенно это касается WebKitGTK и WebView2, у которых
   своя реализация `baseUrl`.
4. **Внешние ссылки**: `url_launcher` или колбэк (§7.6).
5. **`flutter_inappwebview` 6.2** с Linux, когда выйдет из беты. Это
   кандидат на замену desktop-движка без изменения публичного API.
