import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'widgets/stat_card.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('Dashboard'),
            Text('Kaushik Garage', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<DashboardProvider>().fetchDashboardStats(),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(title: 'Today\'s Jobs', value: provider.todayJobs.toString(), icon: Icons.build, color: Colors.blue),
                      StatCard(title: 'In Progress', value: provider.inProgress.toString(), icon: Icons.sync, color: Colors.orange),
                      StatCard(title: 'Awaiting', value: provider.awaitingConfirmation.toString(), icon: Icons.warning, color: Colors.yellow),
                      StatCard(title: 'Revenue', value: '₹${provider.todayRevenue}', icon: Icons.currency_rupee, color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text("Today's Jobs", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (provider.todayJobCards.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No jobs for today.')))
                  else
                    ...provider.todayJobCards.map((job) => JobCardListTile(
                          jobCard: job,
                          onTap: () => context.push('/job-card/${job.id}'),
                        )),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/new-job'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 2) context.push('/history');
          if (index == 3) context.push('/settings');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'New Job'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
