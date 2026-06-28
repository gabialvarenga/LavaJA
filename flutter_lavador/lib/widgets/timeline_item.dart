import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum TimelineDotState { done, current, pending }

class TimelineItem extends StatelessWidget {
  final TimelineDotState state;
  final String label;
  final String? sublabel;
  final bool isLast;

  const TimelineItem({
    Key? key,
    required this.state,
    required this.label,
    this.sublabel,
    this.isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 3),
              decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(width: 1.5, height: 28, color: AppColors.border),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: state == TimelineDotState.current
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: state == TimelineDotState.current
                        ? AppColors.primary
                        : state == TimelineDotState.pending
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                  ),
                ),
                if (sublabel != null)
                  Text(
                    sublabel!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color get _dotColor {
    switch (state) {
      case TimelineDotState.done:
        return AppColors.green;
      case TimelineDotState.current:
        return AppColors.primary;
      case TimelineDotState.pending:
        return AppColors.border;
    }
  }
}
