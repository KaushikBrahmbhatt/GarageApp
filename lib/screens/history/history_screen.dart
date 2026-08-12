import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/job_card.dart';
import '../../services/job_card_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

  Color _statusColor(String status) {
    switch (status) {
      case 'new': return AppColors.primary;
      case 'in_progress': return AppColors.warningText;
      case 'completed': return AppColors.successText;
      default: return AppColors.textSecondary;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'new': return AppColors.primaryLight;
      case 'in_progress': return AppColors.warningBg;
      case 'completed': return AppColors.successBg;
      default: return AppColors.background;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'new': return 'New';
      case 'in_progress': return 'In Progress';
      case 'completed': return 'Completed';
      default: return status;
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
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                                title: Text('JOB-2025-${jc.id.toString().padLeft(6, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                                subtitle: Text('$customerName • $vehicleModel', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₹${jc.finalTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: _statusBg(jc.status), borderRadius: BorderRadius.circular(6)),
                                      child: Text(_statusLabel(jc.status), style: TextStyle(color: _statusColor(jc.status), fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                onTap: () => context.push('/job-card/${jc.id}'),
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
