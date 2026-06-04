import 'dart:io';

import 'package:logger_utils/logger_utils.dart';
import 'package:test/test.dart';

void main() {
  group('initLogging', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('logger_utils_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('configures Logger.root level based on kDebugMode', () {
      initLogging();
      // In test (debug mode), root level should be FINE
      expect(Logger.root.level, Level.FINE);
    });

    test(
      'creates log file with default "app-" prefix when logsDir provided',
      () {
        initLogging(logsDir: tempDir.path);
        Logger('test').info('hello');
        // Give the handler time to write
        final files = tempDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.contains('app-'))
            .toList();
        expect(files, isNotEmpty);
      },
    );

    test('prunes old log files, keeping most recent 5', () {
      // Create 7 fake log files with different mtimes
      for (var i = 0; i < 7; i++) {
        final file = File('${tempDir.path}/app-2026-01-0$i.log');
        file.writeAsStringSync('log $i');
        file.setLastModifiedSync(DateTime(2026).add(Duration(days: i)));
      }
      initLogging(logsDir: tempDir.path);
      final remaining = tempDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('app-'))
          .toList();
      expect(remaining.length, 5);
    });

    test('uses custom filePrefix for log file names', () {
      initLogging(logsDir: tempDir.path, filePrefix: 'myapp');
      Logger('test').info('hello');
      final files = tempDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('myapp-'))
          .toList();
      expect(files, isNotEmpty);
    });

    test('prune only removes files matching the active prefix', () {
      for (var i = 0; i < 6; i++) {
        final f = File('${tempDir.path}/app-2026-02-0$i.log')
          ..writeAsStringSync('x');
        f.setLastModifiedSync(DateTime(2026, 2).add(Duration(days: i)));
      }
      for (var i = 0; i < 2; i++) {
        File('${tempDir.path}/other-2026-02-0$i.log').writeAsStringSync('y');
      }
      initLogging(logsDir: tempDir.path);
      final names = tempDir
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .toList();
      expect(names.where((n) => n.startsWith('app-')).length, 5);
      expect(names.where((n) => n.startsWith('other-')).length, 2);
    });

    test('Logger hierarchy works - child inherits parent level', () {
      initLogging();
      Logger('scrcpy.adb').level = Level.WARNING;
      final child = Logger('scrcpy.adb.client');
      // Child should inherit WARNING from parent
      expect(child.level, Level.WARNING);
    });

    test('calling initLogging twice does not duplicate output', () {
      initLogging();
      initLogging();
      final records = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(records.add);
      Logger('test').info('hello');
      sub.cancel();
      expect(records, hasLength(1));
    });

    test('records are emitted to listeners', () async {
      initLogging();
      final records = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(records.add);
      Logger('test').info('test message');
      await sub.cancel();
      expect(records, hasLength(1));
      expect(records.first.message, 'test message');
      expect(records.first.level, Level.INFO);
    });
  });
}
