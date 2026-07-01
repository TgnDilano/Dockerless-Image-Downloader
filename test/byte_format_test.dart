import 'package:flutter_test/flutter_test.dart';
import 'package:dockerless_image_downloader/utils/byte_format.dart';

void main() {
  group('Byte formatting', () {
    test('bytes', () {
      expect(formatBytes(0), equals('0 B'));
      expect(formatBytes(500), equals('500 B'));
      expect(formatBytes(1023), equals('1023 B'));
    });

    test('kilobytes', () {
      expect(formatBytes(1024), equals('1.0 KB'));
      expect(formatBytes(1536), equals('1.5 KB'));
      expect(formatBytes(1024 * 1023), equals('1023.0 KB'));
    });

    test('megabytes', () {
      expect(formatBytes(1024 * 1024), equals('1.0 MB'));
      expect(formatBytes(5 * 1024 * 1024 + 512 * 1024), equals('5.5 MB'));
    });

    test('gigabytes', () {
      expect(formatBytes(1024 * 1024 * 1024), equals('1.00 GB'));
      expect(formatBytes(2 * 1024 * 1024 * 1024 + 512 * 1024 * 1024), equals('2.50 GB'));
    });
  });
}
