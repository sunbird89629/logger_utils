# Changelog

## 0.0.2 (98f53e3)

### ✨ Features
- add LoggerHttp and LoggingClient for HTTP request/response logging
- print request info (method, URL, headers, body) in prettyResponse
- truncate long string values in JSON bodies via `maxStringLen` (default 100)
- add `logHeader` toggle to prettyResponse

### 🐛 Bug Fixes
- keep status line metadata on one line

### ♻️ Refactoring
- guard lazy logging in infoResponse/infoJson when the level is disabled
- extract `_statusLine` helper

### ✅ Tests
- add prettyResponse test suite

### 🔧 Chores
- add `/release-notes` skill for generating CHANGELOG entries

## 0.0.1

- Initial release: extracted as a standalone library.
- Console + daily-rotated file logging via `initLogging({logsDir, filePrefix})`.
- `prettyJson` / `Logger.infoJson` JSON logging helpers.
- `Logger.trace` / `traceAsync` call tracing.
