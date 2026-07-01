import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class LogConsole extends StatefulWidget {
  final List<String> lines;
  final ScrollController scrollController;

  const LogConsole({
    super.key,
    required this.lines,
    required this.scrollController,
  });

  @override
  State<LogConsole> createState() => _LogConsoleState();
}

class _LogConsoleState extends State<LogConsole> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.holdLine),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: AppColors.hold,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOG',
                          style: AppTypography.display(
                            size: 14.5,
                            color: AppColors.offWhite,
                          ),
                        ),
                        Text(
                          '${widget.lines.length} lines',
                          style: AppTypography.mono(
                            size: 11,
                            color: AppColors.steelTextDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.chevron_left : Icons.expand_more,
                    size: 16,
                    color: AppColors.sealTeal,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              color: AppColors.ink,
              child: ListView.builder(
                controller: widget.scrollController,
                shrinkWrap: true,
                itemCount: widget.lines.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 1,
                    ),
                    child: Text(
                      widget.lines[index],
                      style: AppTypography.mono(
                        size: 12,
                        color: AppColors.logText,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
