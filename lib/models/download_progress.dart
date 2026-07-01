enum LayerStatus { queued, downloading, verifying, done, error }

class LayerProgress {
  final String layerId;
  final String digest;
  final int totalBytes;
  LayerStatus status;
  int downloadedBytes;
  String? errorMessage;

  LayerProgress({
    required this.layerId,
    required this.digest,
    required this.totalBytes,
    this.status = LayerStatus.queued,
    this.downloadedBytes = 0,
    this.errorMessage,
  });

  String get shortId => layerId.length > 12 ? layerId.substring(0, 12) : layerId;
}

enum DownloadPhase {
  idle,
  authenticating,
  fetchingManifest,
  resolvingManifest,
  downloadingLayers,
  finalizing,
  done,
  error,
}

class DownloadState {
  final DownloadPhase phase;
  final String? image;
  final String? tag;
  final String? digest;
  final String? outputPath;
  final List<LayerProgress> layers;
  final List<String> logLines;
  final String? errorMessage;
  final bool isCancelled;
  final double overallProgress;

  DownloadState({
    this.phase = DownloadPhase.idle,
    this.image,
    this.tag,
    this.digest,
    this.outputPath,
    this.layers = const [],
    this.logLines = const [],
    this.errorMessage,
    this.isCancelled = false,
    this.overallProgress = 0.0,
  });

  DownloadState copyWith({
    DownloadPhase? phase,
    String? image,
    String? tag,
    String? digest,
    String? outputPath,
    List<LayerProgress>? layers,
    List<String>? logLines,
    String? errorMessage,
    bool? isCancelled,
    double? overallProgress,
  }) {
    return DownloadState(
      phase: phase ?? this.phase,
      image: image ?? this.image,
      tag: tag ?? this.tag,
      digest: digest ?? this.digest,
      outputPath: outputPath ?? this.outputPath,
      layers: layers ?? this.layers,
      logLines: logLines ?? this.logLines,
      errorMessage: errorMessage,
      isCancelled: isCancelled ?? this.isCancelled,
      overallProgress: overallProgress ?? this.overallProgress,
    );
  }
}
