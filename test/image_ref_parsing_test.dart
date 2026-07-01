import 'package:flutter_test/flutter_test.dart';
import 'package:dockerless_image_downloader/services/image_builder.dart';

void main() {
  group('Image ref parsing', () {
    test('official image without namespace gets library/ prefix', () {
      final result = ImageBuilder.parseImageRef('alpine');
      expect(result.image, equals('library/alpine'));
      expect(result.tag, isNull);
      expect(result.digest, isNull);
    });

    test('official image with tag', () {
      final result = ImageBuilder.parseImageRef('alpine:latest');
      expect(result.image, equals('library/alpine'));
      expect(result.tag, equals('latest'));
      expect(result.digest, isNull);
    });

    test('namespace image', () {
      final result = ImageBuilder.parseImageRef('nginx:1.25');
      expect(result.image, equals('library/nginx'));
      expect(result.tag, equals('1.25'));
    });

    test('namespaced image with namespace', () {
      final result = ImageBuilder.parseImageRef('library/nginx:latest');
      expect(result.image, equals('library/nginx'));
      expect(result.tag, equals('latest'));
    });

    test('custom namespace image', () {
      final result = ImageBuilder.parseImageRef('myuser/myapp:v2');
      expect(result.image, equals('myuser/myapp'));
      expect(result.tag, equals('v2'));
    });

    test('image with digest', () {
      final result = ImageBuilder.parseImageRef(
        'alpine@sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4',
      );
      expect(result.image, equals('library/alpine'));
      expect(result.tag, isNull);
      expect(result.digest,
          equals('sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4'));
    });

    test('image with tag and digest', () {
      final result = ImageBuilder.parseImageRef(
        'alpine:latest@sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4',
      );
      expect(result.image, equals('library/alpine'));
      expect(result.tag, equals('latest'));
      expect(result.digest,
          equals('sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4'));
    });

    test('multi-level namespace', () {
      final result = ImageBuilder.parseImageRef('my.registry.io/myuser/myapp:test');
      expect(result.image, equals('my.registry.io/myuser/myapp'));
      expect(result.tag, equals('test'));
    });
  });
}
