import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/job_card.dart';
import '../../services/job_card_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/rpm_gauge_loader.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedFilter = 'All';
  List<JobCard> _jobCards = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchJobCards();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchJobCards() async {
    setState(() => _isLoading = true);
    try {
      final list = await JobCardService.list();
      setState(() => _jobCards = list);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Loaded jobs');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<JobCard> get _filteredJobCards {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _jobCards.where((jc) {
      final matchesFilter = _selectedFilter == 'All' ||
          (_selectedFilter == 'New' && jc.status == 'new') ||
          (_selectedFilter == 'In Progress' && jc.status == 'in_progress') ||
          (_selectedFilter == 'Completed' && jc.status == 'completed');

      final customerName = (jc.customer?.name ?? '').toLowerCase();
      final vehicleNum = (jc.vehicle?.vehicleNumber ?? '').toLowerCase();
      final jobId = 'job-${jc.id}'.toLowerCase();

      final matchesSearch = q.isEmpty ||
          customerName.contains(q) ||
          vehicleNum.contains(q) ||
          jobId.contains(q);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  void _confirmDeleteJobCard(JobCard jc) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF3A1010),
              child: Icon(Icons.delete_forever, color: AppColors.error, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Remove JOB-2025-${jc.id.toString().padLeft(6, '0')}?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Are you sure you want to remove this job card?\nIt will be soft-deleted and removed from all lists.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Remove Job', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final dashboardProvider = context.read<DashboardProvider>();

      RpmGaugeLoader.show(
        context,
        brandName: 'GarageOS',
        statusMessages: [
          'Removing job card',
          'Updating records',
          'Almost ready',
        ],
      );
      try {
        await JobCardService.deleteJobCard(jc.id);
        await dashboardProvider.fetchDashboardStats();
        await _fetchJobCards();
        if (mounted) RpmGaugeLoader.hide(context);
        Fluttertoast.showToast(msg: 'Job card removed successfully');
      } catch (e) {
        if (mounted) RpmGaugeLoader.hide(context);
        Fluttertoast.showToast(msg: 'Failed to remove job card: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Jobs', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search jobs by ID, customer or vehicle...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: ['All', 'New', 'In Progress', 'Completed'].map((tab) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      showCheckmark: false,
                      label: Text(tab),
                      selected: _selectedFilter == tab,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: _selectedFilter == tab ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
                      onSelected: (_) => setState(() => _selectedFilter = tab),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const SkeletonListLoader()
                : _filteredJobCards.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.work_outline, color: AppColors.textLight, size: 48),
                            SizedBox(height: 12),
                            Text('No jobs found.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _fetchJobCards,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredJobCards.length,
                          itemBuilder: (context, index) {
                            final jc = _filteredJobCards[index];
                            final customerName = jc.customer?.name ?? 'Unknown Customer';
                            final vehicleModel = jc.vehicle != null ? '${jc.vehicle?.brand ?? ''} ${jc.vehicle?.model ?? ''}'.trim() : 'Vehicle';

                            return Card(
                              color: AppColors.surface,
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.primaryLight,
                                  child: Icon(Icons.work, color: AppColors.primary, size: 22),
                                ),
                                title: Text('JOB-${jc.createdAt.year}-${jc.id.toString().padLeft(6, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$customerName • $vehicleModel', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule, size: 12, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('dd MMM yyyy, hh:mm a').format(jc.createdAt),
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₹${jc.finalTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                                    const SizedBox(height: 4),
                                    StatusBadge(status: jc.status, fontSize: 10, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                                  ],
                                ),
                                onTap: () => context.push('/job-card/${jc.id}'),
                                onLongPress: () => _confirmDeleteJobCard(jc),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Job', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => context.push('/new-job'),
      ),
    );
  }
}
