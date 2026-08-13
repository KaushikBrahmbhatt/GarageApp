import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// Centralized Status Badge ensuring 100% color and label consistency across the entire app.
/// Matches the background & text colors used on the Dashboard stat count cards:
/// - New: primaryLight background (soft blue) / primary text
/// - In Progress / Working: warningBg background (soft amber) / warningText text
/// - Completed / Done / Waiting Confirmation: successBg background (soft green) / successText text
class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  static Color getBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return AppColors.primaryLight;
      case 'in_progress':
      case 'working':
        return AppColors.warningBg;
      case 'completed':
      case 'done':
      case 'waiting_confirmation':
      case 'awaiting_confirmation':
        return AppColors.successBg;
      default:
        return AppColors.primaryLight;
    }
  }

  static Color getTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return AppColors.primary;
      case 'in_progress':
      case 'working':
        return AppColors.warningText;
      case 'completed':
      case 'done':
      case 'waiting_confirmation':
      case 'awaiting_confirmation':
        return AppColors.successText;
      default:
        return AppColors.primary;
    }
  }

  static String getLabel(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return 'New';
      case 'in_progress':
      case 'working':
        return 'In Progress';
      case 'completed':
      case 'done':
        return 'Completed';
      case 'waiting_confirmation':
      case 'awaiting_confirmation':
        return 'Awaiting Confirmation';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = getBackgroundColor(status);
    final textColor = getTextColor(status);
    final label = getLabel(status);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
