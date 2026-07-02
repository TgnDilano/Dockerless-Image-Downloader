import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.hold,
        border: Border(right: BorderSide(color: Color(0xFF202020))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Brand block
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.stencilOrange,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'DOCKER\nDOWNLOADER',
            textAlign: TextAlign.center,
            style: AppTypography.display(
              size: 15,
              color: AppColors.offWhite,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'v0.1.0',
            style: AppTypography.mono(size: 10, color: AppColors.steelTextDim),
          ),
          const SizedBox(height: 24),
          // Divider with dot
          SizedBox(
            width: 80,
            child: Row(
              children: [
                const Expanded(
                  child: Divider(color: AppColors.holdLine, thickness: 1),
                ),
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.sealTeal,
                  ),
                ),
                const Expanded(
                  child: Divider(color: AppColors.holdLine, thickness: 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Cargo detail labels
          _label('PORT OF REGISTRY', 'DOCKER HUB'),
          _dividerLine(),
          _label('CARGO TYPE', 'OCI IMAGE'),
          _dividerLine(),
          _label('PROTOCOL', 'HTTPS v2'),
          _dividerLine(),
          _label('DESTINATION', 'LOCAL DISK'),
          const Spacer(),
          // Offline Import card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.hold,
              border: Border.all(color: AppColors.sealTeal.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.cloud_download_outlined,
                      size: 18,
                      color: AppColors.sealTeal,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'OFFLINE IMPORT MODE',
                      style: AppTypography.mono(
                        size: 10,
                        color: AppColors.sealTeal,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'This utility reconstructs original tarball layers on-the-fly without needing any native Docker client. Simply import later via docker load!',
                  style: AppTypography.body(
                    size: 11,
                    color: AppColors.steelTextDim,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _label(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.mono(
              size: 9,
              color: AppColors.steelTextDim,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.display(
              size: 13,
              color: AppColors.offWhite,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dividerLine() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(height: 1, color: AppColors.holdLine),
    );
  }
}
