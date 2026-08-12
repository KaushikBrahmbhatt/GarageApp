import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'widgets/job_card_list_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final staffName = context.watch<AuthProvider>().staffName ?? 'Staff';
    final garageName = context.watch<AuthProvider>().garageName ?? 'Garage';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good Morning 👋 $staffName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text(garageName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<DashboardProvider>().fetchDashboardStats(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 3 Dynamic Stat Cards Row
            Row(
              children: [
                Expanded(child: _buildStatCard(provider.todayJobs.toString(), 'New Jobs', AppColors.primary, AppColors.primaryLight)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard(provider.inProgress.toString(), 'Working', AppColors.warningText, AppColors.warningBg)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard(provider.awaitingConfirmation.toString(), 'Done', AppColors.successText, AppColors.successBg)),
              ],
            ),
            const SizedBox(height: 16),

            // Dynamic Today's Revenue Card
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Today\'s Revenue', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      '₹${provider.todayRevenue.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Today's Jobs Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Today's Jobs", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                TextButton(
                  onPressed: () => context.push('/jobs'),
                  child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (provider.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.primary)))
            else if (provider.todayJobCards.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.work_outline, color: AppColors.textLight, size: 44),
                    SizedBox(height: 12),
                    Text('No jobs created for today.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Tap "+ New Job" to create a new job card.', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                  ],
                ),
              )
            else
              ...provider.todayJobCards.map((job) => JobCardListTile(
                    jobCard: job,
                    onTap: () => context.push('/job-card/${job.id}'),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
