import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/download_progress.dart';
import '../services/registry_service.dart';
import '../services/image_builder.dart';
import '../services/tar_packager.dart';

class DownloadController extends ChangeNotifier {
  late final RegistryService _registry;
  late final ImageBuilder _builder;

  DownloadState _state = DownloadState();
  DownloadState get state => _state;

  final List<String> _logBuffer = [];

  String? _lastImageRef;
  String? _lastOutputPath;

  bool _isDisposed = false;

  DownloadController({RegistryService? registry}) {
    _registry = registry ?? RegistryService(logCallback: _onLog);
    _builder = ImageBuilder(
      registry: _registry,
      logCallback: _onLog,
      layerProgressCallback: _onLayerProgress,
    );
  }

  void _onLog(String line) {
    debugPrint('[DL] $line');
    if (_isDisposed) return;
    _logBuffer.add(line);
    _state = _state.copyWith(
      logLines: List.of(_logBuffer),
    );
    notifyListeners();
  }

  void _onLayerProgress(int index, LayerProgress progress) {
    if (_isDisposed) return;
    final layers = List<LayerProgress>.from(_state.layers);
    if (index < layers.length) {
      layers[index] = progress;
    } else {
      layers.add(progress);
    }
    _state = _state.copyWith(layers: layers);
    notifyListeners();
  }

  Future<void> startDownload(String imageRef, String outputPath) async {
    _lastImageRef = imageRef;
    _lastOutputPath = outputPath;

    _onLog('[Controller] Starting download: imageRef=$imageRef, outputPath=$outputPath');
    final parsed = ImageBuilder.parseImageRef(imageRef);
    final layersCount = _state.layers.length;

    _state = DownloadState(
      phase: DownloadPhase.authenticating,
      image: parsed.image,
      tag: parsed.tag ?? 'latest',
      digest: parsed.digest,
      outputPath: outputPath,
      logLines: List.of(_logBuffer),
      layers: List.generate(
        layersCount > 0 ? layersCount : 0,
        (i) => i < _state.layers.length
            ? _state.layers[i]
            : LayerProgress(layerId: '', digest: '', totalBytes: 0),
      ),
    );
    notifyListeners();

    _state = await _builder.buildImage(
      imageRef: imageRef,
      outputDir: outputPath,
      currentState: _state.copyWith(phase: DownloadPhase.fetchingManifest),
    );
    _state = _state.copyWith(logLines: List.of(_logBuffer));
    notifyListeners();
  }

  Future<String> packageAsTar() async {
    if (_state.image == null || _state.tag == null || _state.outputPath == null) {
      throw Exception('No completed download to package');
    }
    _onLog('Packaging as .tar...');
    final tarPath = await TarPackager.packageToTar(
      directoryPath: _state.outputPath!,
      imageName: _state.image!,
      tag: _state.tag!,
      logCallback: _onLog,
    );
    _onLog('Packaged to $tarPath');
    return tarPath;
  }

  void retry() {
    if (_state.errorMessage == null) return;
    final imageRef = _lastImageRef;
    final outputPath = _lastOutputPath;
    if (imageRef == null || outputPath == null) return;

    _state = _state.copyWith(
      phase: DownloadPhase.idle,
      errorMessage: null,
      isCancelled: false,
    );
    notifyListeners();
    startDownload(imageRef, outputPath);
  }

  void reset() {
    _logBuffer.clear();
    _state = DownloadState();
    _lastImageRef = null;
    _lastOutputPath = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
