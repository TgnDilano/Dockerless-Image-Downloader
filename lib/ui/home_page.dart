import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/download_progress.dart';
import '../state/download_controller.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';
import 'widgets/checkpoint_trail.dart';
import 'widgets/image_input_card.dart';
import 'widgets/layer_progress_tile.dart';
import 'widgets/log_console.dart';
import 'widgets/result_banner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _imageController = TextEditingController();
  final _scrollController = ScrollController();
  final _logScrollController = ScrollController();

  String? _selectedPath;
  String? _validationError;
  bool _isPackaging = false;
  int _fileCount = 0;
  int _totalSize = 0;

  @override
  void initState() {
    super.initState();
    _setDefaultPath();
    _imageController.addListener(() {
      _validateInput(_imageController.text);
    });
  }

  Future<void> _setDefaultPath() async {
    try {
      final dir = await getDownloadsDirectory();
      _selectedPath = dir?.path ?? (await getApplicationDocumentsDirectory()).path;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _validateInput(String value) {
    if (value.trim().isEmpty) {
      setState(() => _validationError = null);
      return;
    }
    final imageRefPattern = RegExp(
      r'^[a-z0-9]+([._-][a-z0-9]+)*(/[a-z0-9]+([._-][a-z0-9]+)*)?'
      r'(:(?:[a-zA-Z0-9_][a-zA-Z0-9._-]*)?'
      r')?(?:@sha256:[a-f0-9]{64})?$',
    );
    if (!imageRefPattern.hasMatch(value.trim())) {
      setState(() {
        _validationError =
            'Invalid format. Use [namespace/]name[:tag][@sha256:digest]';
      });
    } else {
      setState(() => _validationError = null);
    }
  }

  Future<void> _pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() => _selectedPath = result);
    }
  }

  Future<void> _startDownload() async {
    final controller = context.read<DownloadController>();
    await controller.startDownload(
      _imageController.text.trim(),
      _selectedPath!,
    );
    if (controller.state.phase == DownloadPhase.done) {
      await _countFiles(controller.state.outputPath!);
    }
  }

  Future<void> _countFiles(String path) async {
    try {
      final dir = Directory(path);
      int count = 0;
      int size = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          count++;
          size += await entity.length();
        }
      }
      setState(() {
        _fileCount = count;
        _totalSize = size;
      });
    } catch (_) {}
  }

  Future<void> _packageAsTar() async {
    setState(() => _isPackaging = true);
    try {
      final controller = context.read<DownloadController>();
      await controller.packageAsTar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Packaged as .tar successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to package: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPackaging = false);
    }
  }

  @override
  void dispose() {
    _imageController.dispose();
    _scrollController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  String _phaseSubtitle(DownloadPhase phase) {
    switch (phase) {
      case DownloadPhase.authenticating:
        return 'clearing';
      case DownloadPhase.fetchingManifest:
      case DownloadPhase.resolvingManifest:
        return 'fetching';
      case DownloadPhase.downloadingLayers:
        return 'pulling';
      case DownloadPhase.finalizing:
        return 'sealing';
      case DownloadPhase.done:
        return 'stamped';
      case DownloadPhase.error:
        return 'failed';
      default:
        return 'queued';
    }
  }

  List<Checkpoint> _buildCheckpoints(DownloadState state) {
    final phase = state.phase;
    final phases = [
      DownloadPhase.authenticating,
      DownloadPhase.fetchingManifest,
      DownloadPhase.downloadingLayers,
      DownloadPhase.finalizing,
    ];
    final labels = ['Auth', 'Manifest', 'Layers', 'Finalize'];

    return List.generate(4, (i) {
      final p = phases[i];
      final phaseIndex = phase.index;
      final checkpointIndex = p.index;
      final done = phaseIndex > checkpointIndex || phase == DownloadPhase.done;
      final active = phase == p;
      return Checkpoint(
        label: labels[i],
        sub: done
            ? 'done'
            : active
                ? _phaseSubtitle(phase)
                : 'queued',
        done: done,
        active: active,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Consumer<DownloadController>(
        builder: (context, controller, _) {
          final state = controller.state;
          final isDownloading = state.phase == DownloadPhase.authenticating ||
              state.phase == DownloadPhase.fetchingManifest ||
              state.phase == DownloadPhase.resolvingManifest ||
              state.phase == DownloadPhase.downloadingLayers ||
              state.phase == DownloadPhase.finalizing;
          final isDone = state.phase == DownloadPhase.done;
          final isError = state.phase == DownloadPhase.error;

          return SingleChildScrollView(
            controller: _scrollController,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 880),
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 80),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 34),
                    if (isDownloading || isDone || isError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: CheckpointTrail(
                          checkpoints: _buildCheckpoints(state),
                        ),
                      ),
                    ImageInputCard(
                      controller: _imageController,
                      selectedPath: _selectedPath,
                      isLoading: isDownloading,
                      validationError: _validationError,
                      onBrowse: _pickFolder,
                      onDownload: _startDownload,
                      onReset: isDone || isError ? _resetAll : null,
                    ),
                    if (isDone && !isError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.sealTeal,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x26FF6F62),
                                    blurRadius: 0,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pulled directly from the registry \u2014 '
                              'no local Docker daemon needed.',
                              style: AppTypography.mono(
                                size: 11,
                                color: AppColors.graphiteSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Error banner
                    if (isError && state.errorMessage != null)
                      _buildErrorBanner(state.errorMessage!, controller),
                    // Layer progress
                    if (state.layers.isNotEmpty) ...[
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.only(left: 18, bottom: 14),
                        child: Text(
                          'LAYERS',
                          style: AppTypography.display(
                            size: 15,
                            color: const Color(0xFFE7E2D3),
                          ),
                        ),
                      ),
                      ...List.generate(state.layers.length, (i) {
                        return LayerProgressTile(
                          progress: state.layers[i],
                          isLast: i == state.layers.length - 1,
                        );
                      }),
                    ],
                    // Log console
                    if (state.logLines.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      LogConsole(
                        lines: state.logLines,
                        scrollController: _logScrollController,
                      ),
                    ],
                    // Result banner
                    if (isDone && state.outputPath != null) ...[
                      const SizedBox(height: 16),
                      ResultBanner(
                        outputPath: state.outputPath!,
                        fileCount: _fileCount,
                        totalSize: _totalSize,
                        onPackage: _packageAsTar,
                        onDownloadAnother: _resetAll,
                        isPackaging: _isPackaging,
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 22),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.holdLine)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                begin: Alignment(1.55, 0),
                end: Alignment(1.55, 1),
                colors: [AppColors.stencilOrange, AppColors.stencilOrangeDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.stencilOrange.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REGISTRY MANIFEST \u00B7 NO DAEMON REQUIRED',
                  style: AppTypography.mono(
                    size: 11,
                    color: AppColors.stencilOrange,
                    letterSpacing: 1.76,
                  ),
                ),
                Text(
                  'Docker Image Downloader',
                  style: AppTypography.display(
                    size: 26,
                    color: AppColors.offWhite,
                  ),
                ),
                Text(
                  'Pull an image straight to disk, layer by layer.',
                  style: AppTypography.body(
                    size: 13,
                    color: AppColors.steelTextDim,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message, DownloadController controller) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.hold,
        border: Border.all(color: AppColors.stencilOrange.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.stencilOrange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Download failed',
                  style: AppTypography.body(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.steelText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTypography.mono(size: 11, color: AppColors.steelTextDim),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: controller.retry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.stencilOrange,
              foregroundColor: const Color(0xFFFFF6EE),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _resetAll() {
    setState(() {
      _fileCount = 0;
      _totalSize = 0;
      _isPackaging = false;
    });
    _imageController.clear();
    context.read<DownloadController>().reset();
  }
}
