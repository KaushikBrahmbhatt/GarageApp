import 'package:flutter/material.dart';
import '../../../models/job_card.dart';
import '../../../widgets/status_badge.dart';
import '../../../config/app_colors.dart';

class JobCardListTile extends StatelessWidget {
  final JobCard jobCard;
  final VoidCallback onTap;

  const JobCardListTile({super.key, required this.jobCard, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final vehicleInfo = jobCard.vehicle != null
        ? '${jobCard.vehicle?.brand ?? ''} ${jobCard.vehicle?.model ?? ''}'.trim()
        : 'Vehicle';
    final regNum = jobCard.vehicle?.vehicleNumber ?? '';

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        title: Text(
          regNum.isNotEmpty ? regNum : vehicleInfo,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          jobCard.customer?.name ?? 'Unknown Customer',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: StatusBadge(status: jobCard.status),
      ),
    );
  }
}
