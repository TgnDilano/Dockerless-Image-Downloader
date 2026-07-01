import 'package:flutter/material.dart';
import '../../models/download_progress.dart';
import '../../utils/byte_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class LayerProgressTile extends StatelessWidget {
  final LayerProgress progress;
  final bool isLast;

  const LayerProgressTile({
    super.key,
    required this.progress,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = progress.totalBytes > 0
        ? progress.downloadedBytes / progress.totalBytes
        : 0.0;
    final isDownloading = progress.status == LayerStatus.downloading;
    final isDone = progress.status == LayerStatus.done;
    final showProgress = isDownloading || isDone;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: isLast ? 16 : 8,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.hold,
          border: Border.all(color: AppColors.holdLine),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDownloading)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation(AppColors.sealTeal),
                        backgroundColor: AppColors.spinnerTrk,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      isDone ? Icons.check_circle : Icons.circle_outlined,
                      size: 22,
                      color: isDone ? AppColors.sealTeal : AppColors.steelTextDim,
                    ),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.shortId,
                        style: AppTypography.mono(
                          size: 14,
                          weight: FontWeight.w600,
                          color: AppColors.offWhite,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        progress.digest,
                        style: AppTypography.mono(
                          size: 11.5,
                          color: AppColors.steelTextDim,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isDone
                      ? formatBytes(progress.totalBytes)
                      : '${formatBytes(progress.downloadedBytes)} / ${formatBytes(progress.totalBytes)}',
                  style: AppTypography.mono(
                    size: 12,
                    color: AppColors.steelTextDim,
                  ),
                ),
              ],
            ),
            if (showProgress) ...[
              const SizedBox(height: 16),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.trackBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        FractionallySizedBox(
                          widthFactor: ratio.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: const LinearGradient(
                                colors: [AppColors.sealTealDark, AppColors.sealTeal],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
