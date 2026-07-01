import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import '../models/manifest.dart';

class RegistryException implements Exception {
  final String message;
  RegistryException(this.message);
  @override
  String toString() => message;
}

class NetworkException extends RegistryException {
  final int? statusCode;
  NetworkException(super.message, {this.statusCode});
}

class DigestMismatchException extends RegistryException {
  final String expected;
  final String actual;
  DigestMismatchException(this.expected, this.actual)
      : super('Digest mismatch: expected $expected, got $actual');
}

typedef DownloadProgressCallback = void Function(int received, int total);
typedef LogCallback = void Function(String line);

class RegistryService {
  final Dio _dio;
  String? _token;
  String? _tokenImage;
  final LogCallback? _logCallback;

  RegistryService({Dio? dio, LogCallback? logCallback})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
            )),
        _logCallback = logCallback;

  void _log(String line) => _logCallback?.call(line);

  static const _registryUrl = 'https://registry-1.docker.io';
  static const _authUrl = 'https://auth.docker.io';

  Future<String> _getToken(String image) async {
    if (_token != null && _tokenImage == image) {
      _log('[Token] Using cached token for $image');
      return _token!;
    }
    _log('[Token] No cached token, requesting new token');
    final url = Uri.parse(
      '$_authUrl/token?service=registry.docker.io&scope=repository:$image:pull',
    );
    _log('[Token] GET $url');
    try {
      final response = await _dio.getUri(url);
      _log('[Token] Response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        throw NetworkException(
          'Failed to get auth token (HTTP ${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
      final data = response.data as Map<String, dynamic>;
      _token = data['token'] as String;
      _tokenImage = image;
      _log('[Token] Token obtained successfully (starts with: ${_token!.substring(0, 20)}...)');
      return _token!;
    } on DioException catch (e) {
      _log('[Token] DioException: type=${e.type}, message=${e.message}');
      throw _mapDioException(e, 'obtain authentication token');
    }
  }

  Future<RegistryManifest> fetchManifest(
    String image, {
    String? tagOrDigest,
  }) async {
    _log('[Manifest] fetchManifest called: image=$image, tagOrDigest=$tagOrDigest');
    final token = await _getToken(image);
    final ref = tagOrDigest ?? 'latest';
    final url = '$_registryUrl/v2/$image/manifests/$ref';
    _log('[Manifest] URL: $url');

    final acceptHeaders = [
      'application/vnd.oci.image.manifest.v1+json',
      'application/vnd.oci.image.index.v1+json',
      'application/vnd.docker.distribution.manifest.v2+json',
      'application/vnd.docker.distribution.manifest.list.v2+json',
      'application/vnd.docker.distribution.manifest.v1+json',
    ];
    _log('[Manifest] Accept headers: ${acceptHeaders.join(", ")}');

    try {
      final response = await _dio.getUri(
        Uri.parse(url),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': acceptHeaders.join(', '),
          },
        ),
      );
      _log('[Manifest] Response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        throw NetworkException(
          'Failed to fetch manifest (HTTP ${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
      final data = response.data as Map<String, dynamic>;
      final mediaType =
          (data['mediaType'] as String?) ?? response.headers.value('content-type') ?? '';
      _log('[Manifest] Detected mediaType: $mediaType');

      return _parseManifest(data, mediaType);
    } on DioException catch (e) {
      _log('[Manifest] DioException: type=${e.type}, message=${e.message}, response=${e.response?.statusCode}');
      throw _mapDioException(e, 'fetch manifest');
    }
  }

  RegistryManifest _parseManifest(Map<String, dynamic> data, String mediaType) {
    _log('[Manifest] Parsing manifest: mediaType="$mediaType", schemaVersion=${data["schemaVersion"]}');
    if (mediaType.contains('manifest.list') ||
        mediaType.contains('index.v1') ||
        data.containsKey('manifests')) {
      _log('[Manifest] Identified as multi-arch manifest list');
      return ListRegistryManifest(ManifestList.fromJson(data));
    }
    if (mediaType.contains('manifest.v1') ||
        (data['schemaVersion'] == 1)) {
      _log('[Manifest] Identified as legacy v1 manifest');
      return LegacyRegistryManifest(LegacyV1Manifest.fromJson(data));
    }
    _log('[Manifest] Identified as single-arch manifest v2');
    return SingleRegistryManifest(SingleManifest.fromJson(data));
  }

  Future<SingleManifest> resolveManifestList(ManifestList list) async {
    _log('[Manifest] Resolving multi-arch manifest list for amd64/linux...');
    final target = list.findAmd64();
    if (target == null) {
      _log('[Manifest] No amd64/linux entry found in manifest list');
      throw RegistryException(
        'No amd64/linux manifest found in manifest list',
      );
    }
    _log('[Manifest] Found amd64 entry: digest=${target.digest}, mediaType=${target.mediaType}, size=${target.size}');
    return _fetchManifestByDigest(list.raw!['mediaType'] as String? ?? list.mediaType, target);
  }

  Future<SingleManifest> _fetchManifestByDigest(
    String originalMediaType,
    ManifestDescriptor descriptor,
  ) async {
    final image = _tokenImage!;
    final token = _token!;
    final url = '$_registryUrl/v2/$image/manifests/${descriptor.digest}';
    _log('[Manifest] Fetching sub-manifest by digest: $url');

    try {
      final response = await _dio.getUri(
        Uri.parse(url),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': descriptor.mediaType,
          },
        ),
      );
      _log('[Manifest] Sub-manifest response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        throw NetworkException(
          'Failed to fetch sub-manifest (HTTP ${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
      final data = response.data as Map<String, dynamic>;
      final manifest = SingleManifest.fromJson(data);
      _log('[Manifest] Sub-manifest parsed: ${manifest.layers.length} layers, config digest=${manifest.config.digest}');
      return manifest;
    } on DioException catch (e) {
      _log('[Manifest] Sub-manifest DioException: type=${e.type}, message=${e.message}');
      throw _mapDioException(e, 'fetch sub-manifest');
    }
  }

  Future<Uint8List> downloadConfig(String image, String digest) async {
    _log('[Config] Downloading config blob: digest=$digest');
    final token = await _getToken(image);
    final url = '$_registryUrl/v2/$image/blobs/$digest';
    _log('[Config] GET $url');

    try {
      final response = await _dio.getUri(
        Uri.parse(url),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
        ),
      );
      _log('[Config] Response status: ${response.statusCode}, size: ${response.data?.length ?? 0} bytes');
      if (response.statusCode != 200) {
        throw NetworkException(
          'Failed to download config blob (HTTP ${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
      final bytes = response.data as Uint8List;
      _log('[Config] Verifying digest...');
      _verifyDigest(bytes, digest);
      _log('[Config] Config blob verified successfully (${bytes.length} bytes)');
      return bytes;
    } on DioException catch (e) {
      _log('[Config] DioException: type=${e.type}, message=${e.message}');
      throw _mapDioException(e, 'download config blob');
    }
  }

  Future<void> downloadLayer(
    String image,
    String digest,
    String outputPath,
    int expectedSize, {
    DownloadProgressCallback? onProgress,
  }) async {
    _log('[Layer] Downloading layer: digest=$digest, expectedSize=$expectedSize, outputPath=$outputPath');
    final token = await _getToken(image);
    final url = '$_registryUrl/v2/$image/blobs/$digest';
    _log('[Layer] GET $url');

    final tempPath = '$outputPath.part';
    _log('[Layer] Temp file path: $tempPath');

    try {
      await _dio.downloadUri(
        Uri.parse(url),
        tempPath,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
        onReceiveProgress: (received, total) {
          _log('[Layer] Download progress: $received/${total != -1 ? total : expectedSize} bytes');
          onProgress?.call(received, total != -1 ? total : expectedSize);
        },
      );
      final file = File(tempPath);
      if (!await file.exists()) {
        _log('[Layer] ERROR: Download completed but temp file not found at $tempPath');
        throw RegistryException('Download completed but file not found');
      }
      final stat = await file.stat();
      _log('[Layer] Temp file exists, size: ${stat.size} bytes');
      final bytes = await file.readAsBytes();
      _log('[Layer] Verifying digest for layer...');
      _verifyDigest(bytes, digest);
      _log('[Layer] Digest verified, renaming temp file to $outputPath');
      await file.rename(outputPath);
      _log('[Layer] Layer download complete: $outputPath');
    } on DioException catch (e) {
      _log('[Layer] DioException: type=${e.type}, message=${e.message}, response=${e.response?.statusCode}');
      try {
        await File(tempPath).delete();
        _log('[Layer] Cleaned up temp file after error');
      } catch (_) {
        _log('[Layer] Failed to clean up temp file after error');
      }
      throw _mapDioException(e, 'download layer blob');
    } on DigestMismatchException {
      _log('[Layer] DigestMismatchException: file content does not match expected digest');
      try {
        await File(tempPath).delete();
        _log('[Layer] Cleaned up temp file after digest mismatch');
      } catch (_) {
        _log('[Layer] Failed to clean up temp file after digest mismatch');
      }
      rethrow;
    }
  }

  static const sha256DigestLength = 64;

  static bool verifyDigest(List<int> bytes, String expectedDigest) {
    final hash = sha256.convert(bytes);
    final actualDigest = 'sha256:$hash';
    return actualDigest == expectedDigest;
  }

  void _verifyDigest(List<int> bytes, String expectedDigest) {
    _log('[Digest] Verifying: expected=$expectedDigest');
    final hash = sha256.convert(bytes);
    final actualDigest = 'sha256:$hash';
    _log('[Digest] Computed: $actualDigest');
    if (actualDigest != expectedDigest) {
      _log('[Digest] MISMATCH! Expected=$expectedDigest, Actual=$actualDigest');
      throw DigestMismatchException(expectedDigest, actualDigest);
    }
    _log('[Digest] Verified OK');
  }

  RegistryException _mapDioException(DioException e, String context) {
    _log('[Error] DioException while trying to $context');
    _log('[Error]   type: ${e.type}');
    _log('[Error]   message: ${e.message}');
    if (e.response != null) {
      _log('[Error]   statusCode: ${e.response!.statusCode}');
      _log('[Error]   responseHeaders: ${e.response!.headers.map}');
      if (e.response!.data is String) {
        _log('[Error]   responseBody: ${e.response!.data}');
      }
    }
    _log('[Error]   stackTrace: ${e.stackTrace.toString().split("\n").take(5).join("\n")}');

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkException('Connection timed out while trying to $context');
    }
    if (e.type == DioExceptionType.connectionError) {
      return NetworkException(
        'Could not connect to registry while trying to $context',
      );
    }
    if (e.response != null) {
      final status = e.response!.statusCode;
      if (status == 401) {
        return RegistryException('Authentication denied (HTTP 401) while trying to $context');
      }
      if (status == 404) {
        return RegistryException('Image or blob not found (HTTP 404) while trying to $context');
      }
      if (status == 429) {
        return RegistryException('Rate limited by registry (HTTP 429) while trying to $context');
      }
      return NetworkException(
        'Server error (HTTP $status) while trying to $context',
        statusCode: status,
      );
    }
    return NetworkException('Network error while trying to $context: ${e.message}');
  }

  static String parseDigestFromUrl(String url) {
    final uri = Uri.parse(url);
    return uri.pathSegments.last;
  }
}
