# logger_utils

A small Dart logging setup built on [`logging`](https://pub.dev/packages/logging):

- Console sink with colored levels + optional daily-rotated file output (keeps the 5 most recent files)
- `prettyJson` / `Logger.infoJson` for JSON-payload logging
- `Logger.trace` / `traceAsync` for call-site argument/return tracing (FINE level, zero overhead when not loggable)

Pure Dart — works in Flutter, server, and CLI projects.

## Install (git dependency)

```yaml
dependencies:
  logger_utils:
    git:
      url: https://github.com/sunbird89629/logger_utils.git
      ref: v0.1.0
```

## Usage

```dart
import 'package:logger_utils/logger_utils.dart';

void main() {
  initLogging();
  initLogging(logsDir: 'logs', filePrefix: 'myapp');

  final log = Logger('my.module');
  log.info('started');
  log.infoJson('payload', {'a': 1});
  final n = log.trace('square', [3], () => 3 * 3);
}
```

Levels: `FINE` = debug detail / full payload dumps · `INFO` = key events · `WARNING` = recoverable errors. In debug builds the root level is `FINE`; in release it is `INFO`.

## License

MIT
