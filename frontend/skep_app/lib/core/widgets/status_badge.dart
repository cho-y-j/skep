import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType status;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const StatusBadge({
    Key? key,
    required this.label,
    required this.status,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  }) : super(key: key);

  Color _getBackgroundColor() {
    return backgroundColor ?? _mapStatusToColor();
  }

  Color _mapStatusToColor() {
    switch (status) {
      case StatusType.pending:
        return AppColors.statusPending.withOpacity(0.2);
      case StatusType.active:
        return AppColors.statusActive.withOpacity(0.2);
      case StatusType.completed:
        return AppColors.statusCompleted.withOpacity(0.2);
      case StatusType.cancelled:
        return AppColors.statusCancelled.withOpacity(0.2);
    }
  }

  Color _getTextColor() {
    return textColor ?? _mapStatusToTextColor();
  }

  Color _mapStatusToTextColor() {
    switch (status) {
      case StatusType.pending:
        return AppColors.statusPending;
      case StatusType.active:
        return AppColors.statusActive;
      case StatusType.completed:
        return AppColors.statusCompleted;
      case StatusType.cancelled:
        return AppColors.statusCancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getTextColor(),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: _getTextColor(),
          fontSize: fontSize,
        ),
      ),
    );
  }
}

enum StatusType {
  pending,
  active,
  completed,
  cancelled,
}
