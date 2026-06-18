/// HTTP response pretty-printer for logging: formats status, headers, and body.
library;

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'logger_json.dart' show prettyJson;

/// Renders an [http.Response] as a multi-line string for log output.
///
/// Format:
/// ```
/// GET https://example.com/api
///   accept: application/json
///   ...
///
/// 200 OK (123ms, 456 bytes)
///   content-type: application/json
///   ...
///
/// <pretty-printed JSON body, or plain text if not JSON>
/// ```
///
/// - The originating request (method, URL, headers, body) is printed first
///   when available via [http.Response.request]; headers are indented and the
///   body is shown only for [http.Request] (streamed/multipart have none).
/// - Response headers are indented.
/// - The body is run through [prettyJson] so JSON responses are re-indented
///   and non-JSON bodies are returned as-is.
/// - [elapsedMs] and [bodyBytes] are optional metadata shown on the status line.
/// - [maxStringLen] caps long string values in both bodies (defaults to 100)
///   so base64 blobs don't flood the log; pass `null` to disable truncation.
/// - [logHeader] toggles printing of request and response headers (defaults
///   to true).
String prettyResponse(
  http.Response response, {
  int? elapsedMs,
  int? bodyBytes,
  int? maxStringLen = 100,
  bool logHeader = true,
}) {
  final buf = StringBuffer();
  // Status line
  final request=response.request;
  if(request!=null){
    buf.writeln('${request.method} ${request.url}');
  }

  buf.writeln(_statusLine(response, elapsedMs: elapsedMs, bodyBytes: bodyBytes));

  // Request line + headers + body
  if ( request != null) {
    if (logHeader && request.headers.isNotEmpty) {
      buf.writeln();
      request.headers.forEach((k, v) {
        buf.writeln('  $k: $v');
      });
    }
    // Only http.Request carries a readable body; streamed/multipart do not.
    if (request is http.Request && request.body.isNotEmpty) {
      buf.writeln();
      buf.writeln();
      buf.write(prettyJson(request.body, maxStringLen: maxStringLen));
    }
    buf.writeln();
    buf.writeln();
  }
  // Headers
  if (logHeader && response.headers.isNotEmpty) {
    buf.writeln();
    response.headers.forEach((k, v) {
      buf.writeln('  $k: $v');
    });
  }

  // Body — non-empty only
  final body = response.body;
  if (body.isNotEmpty) {
    buf.writeln();
    buf.writeln();
    buf.write(prettyJson(body, maxStringLen: maxStringLen));
  }

  return buf.toString();
}

/// Builds the status line, e.g. `200 OK (123ms, 456 bytes)`.
///
/// [elapsedMs] and [bodyBytes] are appended in parentheses when present.
String _statusLine(http.Response response, {int? elapsedMs, int? bodyBytes}) {
  final line =
      StringBuffer('${response.statusCode} ${response.reasonPhrase ?? ''}');
  final meta = <String>[];
  if (elapsedMs != null) meta.add('${elapsedMs}ms');
  if (bodyBytes != null) meta.add('$bodyBytes bytes');
  if (meta.isNotEmpty) line.write(' (${meta.join(', ')})');
  return line.toString();
}

/// Adds [infoResponse] for logging an HTTP response alongside a message.
extension LoggerHttp on Logger {
  /// Logs [message] at [Level.INFO], appending a formatted [response] on
  /// subsequent lines (status, headers, and pretty-printed body).
  ///
  /// Optionally include [elapsedMs] and [bodyBytes] in the status line, cap
  /// long string values via [maxStringLen], and toggle headers via [logHeader]
  /// (see [prettyResponse]).
  void infoResponse(
    String message,
    http.Response response, {
    int? elapsedMs,
    int? bodyBytes,
    int? maxStringLen = 100,
    bool logHeader = true,
  }) => info(
    '$message\n${prettyResponse(response, elapsedMs: elapsedMs, bodyBytes: bodyBytes, maxStringLen: maxStringLen, logHeader: logHeader)}',
  );
}
