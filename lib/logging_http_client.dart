/// An [http.Client] wrapper that logs every request and response.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// Wraps an inner [http.Client] and logs each request/response at [Level.FINE].
///
/// Drop it in at construction without touching call sites:
///
/// ```dart
/// final client = LoggingClient();              // wraps a fresh http.Client
/// final api = ApiClient(httpClient: client);   // logs every call it makes
/// ```
///
/// When FINE is not loggable, [send] forwards to the inner client untouched —
/// the response stream is **not** buffered, so there is no overhead.
///
/// Bodies are truncated at [maxBodyLog] characters so base64 images / large
/// payloads don't flood the log, and the `Authorization` header is redacted so
/// API keys never leak into log files.
class LoggingClient extends http.BaseClient {
  LoggingClient({http.Client? inner, Logger? logger, this.maxBodyLog = 4096})
    : _inner = inner ?? http.Client(),
      _log = logger ?? Logger('http');

  final http.Client _inner;
  final Logger _log;

  /// Bodies longer than this (in characters) are truncated in the log.
  /// Set to a negative value to log bodies in full.
  final int maxBodyLog;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Fast path: no FINE logging, no buffering, zero overhead.
    if (!_log.isLoggable(Level.FINE)) return _inner.send(request);

    _log.fine(
      '=> ${request.method} ${request.url}\n'
      '${_formatHeaders(request.headers)}'
      '${_requestBody(request)}',
    );

    final sw = Stopwatch()..start();
    final response = await _inner.send(request);

    // Buffer the body so it can be logged, then hand a fresh stream downstream.
    final bytes = await response.stream.toBytes();
    sw.stop();

    _log.fine(
      '<= ${response.statusCode} ${request.method} ${request.url} '
      '(${sw.elapsedMilliseconds}ms)\n'
      '${_formatHeaders(response.headers)}'
      '${_truncate(_decodeBody(bytes))}',
    );

    return http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      contentLength: bytes.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();

  /// Only [http.Request] exposes a string body; streamed/multipart bodies are
  /// skipped rather than drained (draining would break the actual request).
  String _requestBody(http.BaseRequest request) {
    if (request is http.Request && request.body.isNotEmpty) {
      return _truncate(request.body);
    }
    return '';
  }

  String _decodeBody(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return '<${bytes.length} bytes binary>';
    }
  }

  String _truncate(String body) {
    if (maxBodyLog < 0 || body.length <= maxBodyLog) return body;
    return '${body.substring(0, maxBodyLog)}… (${body.length} chars total)';
  }

  String _formatHeaders(Map<String, String> headers) {
    final lines = headers.entries.map((e) {
      final value = e.key.toLowerCase() == 'authorization' ? '***' : e.value;
      return '  ${e.key}: $value';
    });
    return lines.isEmpty ? '' : '${lines.join('\n')}\n';
  }
}
