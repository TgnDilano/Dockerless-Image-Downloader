import 'package:flutter/material.dart';
import '../../models/download_progress.dart';
import '../../utils/byte_format.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusIcon = _buildStatusIcon(colorScheme);

    return Card(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 4,
        bottom: isLast ? 16 : 4,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                statusIcon,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.shortId,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (progress.digest.isNotEmpty)
                        Text(
                          progress.digest,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  '${formatBytes(progress.downloadedBytes)} / ${formatBytes(progress.totalBytes)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (progress.status == LayerStatus.downloading ||
                progress.status == LayerStatus.queued) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.totalBytes > 0
                      ? progress.downloadedBytes / progress.totalBytes
                      : null,
                  minHeight: 6,
                  semanticsLabel: 'Layer ${progress.shortId}: '
                      '${(progress.totalBytes > 0 ? progress.downloadedBytes / progress.totalBytes * 100 : 0).toStringAsFixed(0)}%',
                ),
              ),
            ],
            if (progress.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  progress.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ColorScheme colorScheme) {
    switch (progress.status) {
      case LayerStatus.queued:
        return Icon(Icons.hourglass_empty, size: 20, color: colorScheme.onSurfaceVariant);
      case LayerStatus.downloading:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: progress.totalBytes > 0
                ? progress.downloadedBytes / progress.totalBytes
                : null,
          ),
        );
      case LayerStatus.verifying:
        return Icon(Icons.verified, size: 20, color: colorScheme.tertiary);
      case LayerStatus.done:
        return Icon(Icons.check_circle, size: 20, color: colorScheme.primary);
      case LayerStatus.error:
        return Icon(Icons.error, size: 20, color: colorScheme.error);
    }
  }


}
