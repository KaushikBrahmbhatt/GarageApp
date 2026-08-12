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
    final staffName = context.watch<AuthProvider>().staffName ?? 'Suresh';
    final garageName = context.watch<AuthProvider>().garageName ?? 'Shree Auto Garage';

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
        onRefresh: () => context.read<DashboardProvider>().fetchDashboardStats(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 3 Stat Cards Row
            Row(
              children: [
                Expanded(child: _buildStatCard('12', 'New Jobs', AppColors.primary, AppColors.primaryLight)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('5', 'Working', AppColors.warningText, AppColors.warningBg)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('7', 'Done', AppColors.successText, AppColors.successBg)),
              ],
            ),
            const SizedBox(height: 16),

            // Today's Revenue Card
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
                      '₹${provider.todayRevenue > 0 ? provider.todayRevenue.toStringAsFixed(0) : '12,450'}',
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
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (provider.todayJobCards.isEmpty) ...[
              // Blueprint Sample Items
              _buildSampleJobTile('Rahul Sharma', 'Honda Activa 6G', '₹450', 'Working', AppColors.warningText, AppColors.warningBg),
              _buildSampleJobTile('Amit Patel', 'TVS Jupiter', '₹300', 'New', AppColors.primary, AppColors.primaryLight),
              _buildSampleJobTile('Vijay Joshi', 'Honda Shine', '₹750', 'Done', AppColors.successText, AppColors.successBg),
            ] else
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

  Widget _buildSampleJobTile(String customer, String vehicle, String amount, String status, Color statusColor, Color statusBg) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.two_wheeler, color: AppColors.primary, size: 22),
        ),
        title: Text('$customer • $vehicle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
        subtitle: Text(amount, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
          child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        onTap: () => context.push('/new-job'),
      ),
    );
  }
}
