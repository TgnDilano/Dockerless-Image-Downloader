import 'dart:convert';
import 'dart:io';
import '../models/manifest.dart';
import '../models/download_progress.dart';
import '../utils/layer_id.dart';
import 'registry_service.dart';

typedef LogCallback = void Function(String line);
typedef LayerProgressCallback = void Function(int index, LayerProgress progress);

class ImageBuilder {
  final RegistryService _registry;
  final LogCallback? _logCallback;
  final LayerProgressCallback? _layerProgressCallback;

  ImageBuilder({
    required RegistryService registry,
    LogCallback? logCallback,
    LayerProgressCallback? layerProgressCallback,
  })  : _registry = registry,
        _logCallback = logCallback,
        _layerProgressCallback = layerProgressCallback;

  void _log(String line) => _logCallback?.call(line);

  void _updateLayer(int index, LayerProgress progress) {
    _layerProgressCallback?.call(index, progress);
  }

  static ({String image, String? tag, String? digest}) parseImageRef(
    String input,
  ) {
    String image = input.trim();
    String? tag;
    String? digest;

    if (image.contains('@')) {
      final parts = image.split('@');
      image = parts[0];
      digest = parts.sublist(1).join('@');
    }

    if (image.contains(':')) {
      final parts = image.split(':');
      image = parts[0];
      tag = parts.sublist(1).join(':');
    }

    if (!image.contains('/')) {
      image = 'library/$image';
    }

    return (image: image, tag: tag, digest: digest);
  }

  Future<DownloadState> buildImage({
    required String imageRef,
    required String outputDir,
    required DownloadState currentState,
  }) async {
    final parsed = parseImageRef(imageRef);
    final image = parsed.image;
    final tag = parsed.tag ?? 'latest';
    final ref = parsed.digest ?? tag;
    final imageDir = '${image.replaceAll('/', '_')}_$tag';

    _log('[Build] ===== Starting image build =====');
    _log('[Build] Input: $imageRef');
    _log('[Build] Parsed: image=$image, tag=$tag, digest=${parsed.digest}, ref=$ref');
    _log('[Build] Output directory: $outputDir/$imageDir');

    try {
      // Phase: Fetching manifest
      _log('[Build] Phase: Fetching manifest...');
      _log('[Build] Fetching manifest for $image:$ref...');
      final registryManifest = await _registry.fetchManifest(image, tagOrDigest: ref);
      _log('[Build] Manifest fetched successfully, type: ${registryManifest.runtimeType}');

      SingleManifest manifest;
      if (registryManifest is ListRegistryManifest) {
        _log('[Build] Detected multi-arch manifest list, resolving for amd64/linux...');
        manifest = await _registry.resolveManifestList(registryManifest.manifest);
        _log('[Build] Resolved to amd64 manifest: ${manifest.layers.length} layers, config=${manifest.config.digest}');
      } else if (registryManifest is SingleRegistryManifest) {
        manifest = registryManifest.manifest;
        _log('[Build] Single-arch manifest: ${manifest.layers.length} layers, config=${manifest.config.digest}');
      } else if (registryManifest is LegacyRegistryManifest) {
        _log('[Build] ERROR: Legacy v1 manifest not supported');
        throw RegistryException(
          'Schema v1 manifests are not supported. Image uses legacy format.',
        );
      } else {
        _log('[Build] ERROR: Unknown manifest format: ${registryManifest.runtimeType}');
        throw RegistryException('Unknown manifest format');
      }

      // Log layer details
      for (int i = 0; i < manifest.layers.length; i++) {
        final blob = manifest.layers[i];
        _log('[Build]   Layer $i: digest=${blob.digest}, size=${blob.size}, mediaType=${blob.mediaType}');
      }

      final absDir = '$outputDir${Platform.pathSeparator}$imageDir';
      _log('[Build] Creating output directory: $absDir');
      final dir = Directory(absDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        _log('[Build] Output directory created');
      } else {
        _log('[Build] Output directory already exists');
      }

      // Phase: Downloading config blob
      _log('[Build] Phase: Downloading config blob...');
      _log('[Build] Config digest: ${manifest.config.digest}, size: ${manifest.config.size}');
      final configBytes = await _registry.downloadConfig(image, manifest.config.digest);
      _log('[Build] Config blob downloaded: ${configBytes.length} bytes');
      final configHash = manifest.config.digest.replaceAll('sha256:', '');
      final configPath = '$absDir${Platform.pathSeparator}$configHash.json';
      _log('[Build] Writing config to: $configPath');
      await File(configPath).writeAsBytes(configBytes);
      _log('[Build] Config blob saved');

      // Phase: Downloading layers
      _log('[Build] Phase: Downloading layers (${manifest.layers.length} total)...');
      final layers = <String>[];
      String? parentId;

      for (int i = 0; i < manifest.layers.length; i++) {
        _log('[Build] ===== Layer ${i + 1}/${manifest.layers.length} =====');
        final blob = manifest.layers[i];
        final layerId = computeLayerId(parentId, blob.digest);
        _log('[Build] Layer ID: $layerId (parentId=${parentId ?? "none"})');
        final layerDir = '$absDir${Platform.pathSeparator}$layerId';
        final layerDirEntity = Directory(layerDir);

        if (!await layerDirEntity.exists()) {
          await layerDirEntity.create(recursive: true);
          _log('[Build] Layer directory created: $layerDir');
        } else {
          _log('[Build] Layer directory already exists: $layerDir');
        }

        // Write VERSION file
        _log('[Build] Writing VERSION file');
        await File('$layerDir${Platform.pathSeparator}VERSION').writeAsString('1.0\n');

        // Write legacy json file
        _log('[Build] Writing legacy json file');
        final legacyJson = _buildLegacyLayerJson(layerId, parentId);
        await File('$layerDir${Platform.pathSeparator}json')
            .writeAsString(const JsonEncoder.withIndent('    ').convert(legacyJson));

        // Download layer blob
        final layerTarPath = '$layerDir${Platform.pathSeparator}layer.tar';
        final layerFile = File(layerTarPath);
        bool needsDownload = true;

        if (await layerFile.exists()) {
          _log('[Build] Layer tar already exists, checking size and digest...');
          final stat = await layerFile.stat();
          _log('[Build]   Existing file size: ${stat.size} bytes');
          if (stat.size > 0) {
            try {
              final existingBytes = await layerFile.readAsBytes();
              final valid = RegistryService.verifyDigest(existingBytes, blob.digest);
              _log('[Build]   Existing digest valid: $valid');
              if (valid) {
                needsDownload = false;
                _log('[Build] Layer ${blob.digest} already downloaded and verified, skipping');
              } else {
                _log('[Build] Existing file digest mismatch, re-downloading');
              }
            } catch (e) {
              _log('[Build] Error verifying existing file: $e, re-downloading');
              needsDownload = true;
            }
          } else {
            _log('[Build] Existing file is empty, re-downloading');
          }
        }

        if (needsDownload) {
          _log('[Build] Downloading layer ${i + 1}/${manifest.layers.length}: digest=${blob.digest}, size=${blob.size}');
          await _registry.downloadLayer(
            image,
            blob.digest,
            layerTarPath,
            blob.size,
            onProgress: (received, total) {
              _updateLayer(
                i,
                LayerProgress(
                  layerId: layerId,
                  digest: blob.digest,
                  totalBytes: total,
                  status: LayerStatus.downloading,
                  downloadedBytes: received,
                ),
              );
            },
          );
          _log('[Build] Layer ${i + 1} downloaded and verified successfully');
        }

        _updateLayer(
          i,
          LayerProgress(
            layerId: layerId,
            digest: blob.digest,
            totalBytes: blob.size,
            status: LayerStatus.done,
            downloadedBytes: blob.size,
          ),
        );

        layers.add('$layerId/layer.tar');
        parentId = layerId;
        _log('[Build] Layer ${i + 1} complete, new parentId=$parentId');
      }

      // Phase: Finalizing — patch top layer's json with config blob data
      _log('[Build] Phase: Finalizing image structure...');
      if (manifest.layers.isNotEmpty) {
        final topLayerId = layers.last.replaceAll('/layer.tar', '');
        _log('[Build] Patching top layer json: $topLayerId');
        final topJsonPath =
            '$absDir${Platform.pathSeparator}$topLayerId${Platform.pathSeparator}json';
        _log('[Build] Top json path: $topJsonPath');

        final configJson = json.decode(utf8.decode(configBytes)) as Map<String, dynamic>;
        _log('[Build] Config keys: ${configJson.keys.join(", ")}');
        final mungedConfig = Map<String, dynamic>.from(configJson);
        mungedConfig.remove('history');
        mungedConfig.remove('rootfs');
        mungedConfig['id'] = topLayerId;

        final prevParentId =
            manifest.layers.length > 1
                ? layers[layers.length - 2].replaceAll('/layer.tar', '')
                : null;
        if (prevParentId != null) {
          _log('[Build] Setting parent: $prevParentId');
          mungedConfig['parent'] = prevParentId;
        } else {
          mungedConfig.remove('parent');
        }

        await File(topJsonPath).writeAsString(
          const JsonEncoder.withIndent('    ').convert(mungedConfig),
        );
        _log('[Build] Top layer configuration finalized');
      } else {
        _log('[Build] No layers to finalize (empty manifest)');
      }

      // Write repositories file
      _log('[Build] Writing repositories file...');
      final topLayerId =
          layers.isNotEmpty ? layers.last.replaceAll('/layer.tar', '') : '';
      final repositories = <String, Map<String, String>>{
        image: {tag: topLayerId},
      };
      await File('$absDir${Platform.pathSeparator}repositories')
          .writeAsString(const JsonEncoder.withIndent('    ').convert(repositories));
      _log('[Build] Repositories file written: $image:$tag -> $topLayerId');

      // Write manifest.json
      _log('[Build] Writing manifest.json...');
      final manifestEntry = ManifestEntry(
        config: '$configHash.json',
        repoTags: ['$image:$tag'],
        layers: layers,
      );
      _log('[Build] Manifest config ref: $configHash.json');
      _log('[Build] Manifest layers: ${layers.join(", ")}');
      final manifestJsonList = [manifestEntry.toJson()];
      await File('$absDir${Platform.pathSeparator}manifest.json').writeAsString(
        const JsonEncoder.withIndent('    ').convert(manifestJsonList),
      );
      _log('[Build] manifest.json written');

      _log('[Build] ===== Download complete! =====');
      _log('[Build] Image saved to: $absDir');

      return currentState.copyWith(
        phase: DownloadPhase.done,
        outputPath: absDir,
        overallProgress: 1.0,
      );
    } on RegistryException catch (e) {
      _log('[Build] RegistryException: ${e.message}');
      return currentState.copyWith(
        phase: DownloadPhase.error,
        errorMessage: e.message,
      );
    } catch (e) {
      _log('[Build] Unexpected error: $e');
      _log('[Build] Stack trace: ${StackTrace.current}');
      return currentState.copyWith(
        phase: DownloadPhase.error,
        errorMessage: 'Unexpected error: $e',
      );
    }
  }

  Map<String, dynamic> _buildLegacyLayerJson(String layerId, String? parentId) {
    final Map<String, dynamic> json = {
      'id': layerId,
      'created': '0001-01-01T00:00:00Z',
      'container_config': {
        'Hostname': '',
        'Domainname': '',
        'User': '',
        'AttachStdin': false,
        'AttachStdout': false,
        'AttachStderr': false,
        'Tty': false,
        'OpenStdin': false,
        'StdinOnce': false,
        'Env': null,
        'Cmd': null,
        'Image': '',
        'Volumes': null,
        'WorkingDir': '',
        'Entrypoint': null,
        'OnBuild': null,
        'Labels': null,
      },
    };
    if (parentId != null) {
      json['parent'] = parentId;
    }
    return json;
  }
}
