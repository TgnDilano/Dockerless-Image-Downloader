import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dockerless_image_downloader/utils/layer_id.dart';

void main() {
  group('Layer ID computation', () {
    test('first layer with null parent', () {
      final digest = 'sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4';
      final id = computeLayerId(null, digest);
      final expected = 'sha256:${sha256.convert(utf8.encode('\n$digest')).toString()}';
      expect(id, equals(expected));
    });

    test('second layer with previous parent', () {
      final parentId = 'sha256:layer1_hash';
      final digest = 'sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4';
      final id = computeLayerId(parentId, digest);
      final expected = 'sha256:${sha256.convert(utf8.encode('$parentId\n$digest')).toString()}';
      expect(id, equals(expected));
    });

    test('chaining three layers matches expected pattern', () {
      final digests = [
        'sha256:1111111111111111111111111111111111111111111111111111111111111111',
        'sha256:2222222222222222222222222222222222222222222222222222222222222222',
        'sha256:3333333333333333333333333333333333333333333333333333333333333333',
      ];

      String? parentId;
      for (final digest in digests) {
        final id = computeLayerId(parentId, digest);
        final input = '${parentId ?? ''}\n$digest';
        final expected = 'sha256:${sha256.convert(utf8.encode(input)).toString()}';
        expect(id, equals(expected));
        parentId = id;
      }
    });
  });
}
