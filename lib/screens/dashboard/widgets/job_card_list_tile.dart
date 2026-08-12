import 'package:flutter/material.dart';
import '../../../models/job_card.dart';
import '../../../config/theme.dart';

class JobCardListTile extends StatelessWidget {
  final JobCard jobCard;
  final VoidCallback onTap;

  const JobCardListTile({super.key, required this.jobCard, required this.onTap});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new': return Colors.grey;
      case 'in_progress': return AppTheme.kPrimary;
      case 'waiting_confirmation': return AppTheme.kWarning;
      case 'completed': return AppTheme.kSuccess;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        title: Text(jobCard.vehicle?.vehicleNumber ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(jobCard.customer?.name ?? 'Unknown Customer'),
        trailing: Chip(
          label: Text(jobCard.status.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
          backgroundColor: _getStatusColor(jobCard.status),
        ),
      ),
    );
  }
}
