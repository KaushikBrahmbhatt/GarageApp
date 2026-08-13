import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(jobCard.createdAt);

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        title: Text(
          regNum.isNotEmpty ? '$regNum • $vehicleInfo' : vehicleInfo,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              jobCard.customer?.name ?? 'Unknown Customer',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.schedule, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        trailing: StatusBadge(status: jobCard.status),
      ),
    );
  }
}
