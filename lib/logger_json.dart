/// JSON-aware logging for [Logger]: pretty-prints payloads as indented JSON.
library;

import 'dart:convert';

import 'package:logging/logging.dart';

// Falls back to toString() for any object the encoder can't handle, so
// prettyJson never throws on unexpected payloads.
const _encoder = JsonEncoder.withIndent('  ', _stringify);

Object _stringify(Object? value) => '$value';

/// Renders [value] as indented JSON for logs.
///
/// - [Map]/[List] (or any JSON-encodable object) → 2-space indented JSON.
/// - [String] → parsed as JSON then re-indented; returned as-is if it is
///   not valid JSON.
/// - Anything not encodable → `toString()`.
///
/// When [maxStringLen] is set, any string *value* longer than it is truncated
/// to `<first maxStringLen chars>…<N chars omitted>`, recursing through maps
/// and lists. Keys are never touched, so the JSON structure stays intact —
/// useful for payloads carrying long base64 blobs (e.g. images). A non-JSON
/// string body is truncated as a whole.
///
/// Non-ASCII text (e.g. Chinese) is kept verbatim — Dart's encoder does not
/// escape it to `\uXXXX`. This never throws.
String prettyJson(Object? value, {int? maxStringLen}) {
  var decoded = value;
  if (value is String) {
    try {
      decoded = jsonDecode(value);
    } on FormatException {
      return maxStringLen == null ? value : _truncate(value, maxStringLen);
    }
  }
  if (maxStringLen != null) decoded = _truncateStrings(decoded, maxStringLen);
  return _encoder.convert(decoded);
}

/// Recursively truncates long string values within maps and lists.
Object? _truncateStrings(Object? value, int maxLen) {
  if (value is String) return _truncate(value, maxLen);
  if (value is Map) {
    return value.map((k, v) => MapEntry(k, _truncateStrings(v, maxLen)));
  }
  if (value is List) {
    return value.map((v) => _truncateStrings(v, maxLen)).toList();
  }
  return value;
}

String _truncate(String s, int maxLen) {
  if (s.length <= maxLen) return s;
  return '${s.substring(0, maxLen)}…<${s.length - maxLen} chars omitted>';
}

/// Adds [infoJson] for logging a message alongside a pretty-printed payload.
extension LoggerJson on Logger {
  /// Logs [message] at [Level.INFO], appending [payload] as indented JSON on
  /// the next line. [payload] may be a JSON-encodable object or a JSON string.
  void infoJson(String message, Object? payload) {
    if (!isLoggable(Level.INFO)) return;
    info('$message\n${prettyJson(payload)}');
  }
}
