import 'package:http/http.dart' as http;
import 'package:logger_utils/logger_http.dart';
import 'package:test/test.dart';

void main() {
  group('prettyResponse', () {
    http.Response responseWith(http.BaseRequest request) => http.Response(
          '{"ok":true}',
          200,
          headers: {'content-type': 'application/json'},
          reasonPhrase: 'OK',
          request: request,
        );

    test('renders status line, request line and bodies', () {
      final req = http.Request('POST', Uri.parse('https://example.com/api'))
        ..headers['accept'] = 'application/json'
        ..body = '{"name":"foo"}';

      final out = prettyResponse(responseWith(req),
          elapsedMs: 12, bodyBytes: 11);
      

      print(out);

      expect(out, contains('POST https://example.com/api'));
      expect(out, contains('200 OK'));
      expect(out, contains('12ms'));
      expect(out, contains('11 bytes'));
      expect(out, contains('accept: application/json')); // request header
      expect(out, contains('"name": "foo"')); // request body, re-indented
      expect(out, contains('"ok": true')); // response body
    });

    test('logHeader: false hides request and response headers', () {
      final req = http.Request('GET', Uri.parse('https://example.com/api'))
        ..headers['accept'] = 'application/json';

      final out = prettyResponse(responseWith(req), logHeader: false);

      expect(out, contains('GET https://example.com/api'));
      expect(out, contains('200 OK'));
      expect(out, isNot(contains('accept: application/json')));
      expect(out, isNot(contains('content-type: application/json')));
    });

    test('truncates long string values by maxStringLen', () {
      final req = http.Request('POST', Uri.parse('https://example.com/api'))
        ..body = '{"img":"${'A' * 300}"}';

      final out = prettyResponse(responseWith(req), maxStringLen: 100);

      expect(out, contains('…<200 chars omitted>'));
      expect(out, isNot(contains('A' * 101)));
    });

    test('maxStringLen: null keeps the full body', () {
      final req = http.Request('POST', Uri.parse('https://example.com/api'))
        ..body = '{"img":"${'A' * 300}"}';

      final out = prettyResponse(responseWith(req), maxStringLen: null);

      expect(out, contains('A' * 300));
      expect(out, isNot(contains('chars omitted')));
    });

    test('omits the request line when there is no request', () {
      final out = prettyResponse(http.Response('{"ok":true}', 200));

      expect(out, contains('200'));
      expect(out, contains('"ok": true'));
      expect(out, isNot(contains('https://')));
    });
  });
}
