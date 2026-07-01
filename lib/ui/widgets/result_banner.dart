import 'package:flutter/material.dart';
import '../../utils/byte_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ResultBanner extends StatelessWidget {
  final String outputPath;
  final int fileCount;
  final int totalSize;
  final VoidCallback onPackage;
  final VoidCallback onDownloadAnother;
  final bool isPackaging;

  const ResultBanner({
    super.key,
    required this.outputPath,
    required this.fileCount,
    required this.totalSize,
    required this.onPackage,
    required this.onDownloadAnother,
    this.isPackaging = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.hold,
        border: Border.all(color: AppColors.holdLine),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sealTeal,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                'DOWNLOAD COMPLETE',
                style: AppTypography.display(size: 15, color: AppColors.offWhite),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('Files', '$fileCount'),
          _infoRow('Size', formatBytes(totalSize)),
          _infoRow('Path', outputPath),
          if (!isPackaging) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: onPackage,
                icon: const Icon(Icons.archive_outlined, size: 17),
                label: const Text('PACKAGE AS .TAR'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.stencilOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                  textStyle: AppTypography.display(size: 15, color: const Color(0xFFFFF6EE)),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.sealTeal),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'PACKAGING\u2026',
                      style: AppTypography.display(
                        size: 15,
                        color: AppColors.steelTextDim,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onDownloadAnother,
              icon: const Icon(Icons.add, size: 17),
              label: const Text('DOWNLOAD ANOTHER'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.steelTextDim,
                side: const BorderSide(color: AppColors.resetBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                textStyle: AppTypography.body(size: 13, weight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.mono(size: 11, color: AppColors.steelTextDim),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.mono(size: 11, color: AppColors.steelText),
            ),
          ),
        ],
      ),
    );
  }
}
