import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/job_card.dart';
import '../../providers/job_card_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/job_card_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/rpm_gauge_loader.dart';
import 'package:fluttertoast/fluttertoast.dart';

class JobCardScreen extends StatefulWidget {
  final int id;
  const JobCardScreen({super.key, required this.id});

  @override
  State<JobCardScreen> createState() => _JobCardScreenState();
}

class _JobCardScreenState extends State<JobCardScreen> {
  bool _updatingStatus = false;
  final Set<int> _deletingItemIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobCardProvider>().fetchJobCard(widget.id);
    });
  }

  @override
  void didUpdateWidget(JobCardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<JobCardProvider>().fetchJobCard(widget.id);
      });
    }
  }

  Future<void> _updateStatus(JobCard jobCard, String newStatus) async {
    setState(() => _updatingStatus = true);
    try {
      await JobCardService.updateStatus(jobCard.id, newStatus);
      if (mounted) await context.read<JobCardProvider>().fetchJobCard(widget.id);
      Fluttertoast.showToast(msg: 'Job marked as ${newStatus.replaceAll('_', ' ')}');
    } catch (e) {
      // BUG-10 fix: show error to user instead of swallowing it
      Fluttertoast.showToast(msg: 'Failed to update status: ${e.toString().replaceFirst('Exception: ', '')}');
      if (mounted) await context.read<JobCardProvider>().fetchJobCard(widget.id);
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  void _confirmDeleteJobCard(JobCard jobCard) async {
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
              'Remove JOB-2025-${jobCard.id.toString().padLeft(6, '0')}?',
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
      final router = GoRouter.of(context);

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
        await JobCardService.deleteJobCard(jobCard.id);
        await dashboardProvider.fetchDashboardStats();
        if (mounted) RpmGaugeLoader.hide(context);
        Fluttertoast.showToast(msg: 'Job card removed successfully');
        router.go('/dashboard');
      } catch (e) {
        if (mounted) RpmGaugeLoader.hide(context);
        Fluttertoast.showToast(msg: 'Failed to remove job card: $e');
      }
    }
  }

  void _showAddExtraWorkSheet(JobCard jobCard) {
    final searchCtrl = TextEditingController();
    final List<Map<String, dynamic>> masterWorkOptions = [
      {'name': 'General Service', 'price': 300.0, 'type': 'service'},
      {'name': 'Oil Change', 'price': 150.0, 'type': 'service'},
      {'name': 'Brake Check', 'price': 200.0, 'type': 'service'},
      {'name': 'Battery Check', 'price': 250.0, 'type': 'service'},
      {'name': 'Engine Check', 'price': 250.0, 'type': 'service'},
      {'name': 'Brake Liner Replacement', 'price': 450.0, 'type': 'repair'},
      {'name': 'Air Filter', 'price': 120.0, 'type': 'part'},
      {'name': 'Spark Plug', 'price': 90.0, 'type': 'part'},
      {'name': 'Engine Oil (10W30)', 'price': 450.0, 'type': 'part'},
      {'name': 'Chain Set', 'price': 550.0, 'type': 'part'},
      {'name': 'Clutch Adjustment', 'price': 150.0, 'type': 'repair'},
    ];

    final existingNames = jobCard.items.map((i) => i.description.trim().toLowerCase()).toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final query = searchCtrl.text.trim().toLowerCase();
          final availableOptions = masterWorkOptions.where((opt) {
            final name = (opt['name'] as String).trim().toLowerCase();
            final alreadyAdded = existingNames.contains(name);
            final matchesQuery = query.isEmpty || name.contains(query);
            return !alreadyAdded && matchesQuery;
          }).toList();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Extra Work', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search services, repairs or parts...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  ),
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 12),
                const Text('Available Options:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                  child: availableOptions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text('No extra work items available to add.', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: availableOptions.length,
                          itemBuilder: (ctx, index) {
                            final opt = availableOptions[index];
                            return Card(
                              color: AppColors.background,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(opt['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                subtitle: Text('Type: ${(opt['type'] as String).toUpperCase()}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('₹${(opt['price'] as double).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.extraWork, fontSize: 15)),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle, color: AppColors.primary),
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        try {
                                          await JobCardService.addItem(jobCard.id, {
                                            'type': (opt['type'] as String).toLowerCase(),
                                            'description': opt['name'],
                                            'price': opt['price'],
                                            'flag': 'none',
                                          });
                                          if (mounted) {
                                            await context.read<JobCardProvider>().fetchJobCard(widget.id, silent: true);
                                            Fluttertoast.showToast(msg: '${opt['name']} added to job!');
                                          }
                                        } catch (e) {
                                          Fluttertoast.showToast(msg: 'Error adding item: $e');
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobCardProvider>();

    if (provider.isLoading && (provider.currentJobCard == null || provider.currentJobCard!.id != widget.id)) {
      return _buildJobCardSkeleton();
    }

    if (provider.currentJobCard == null || provider.currentJobCard!.id != widget.id) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('JOB-2025-${widget.id.toString().padLeft(6, '0')}', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 54, color: AppColors.error),
                const SizedBox(height: 16),
                const Text('Job Card Not Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(provider.error.isNotEmpty ? provider.error : 'Job card #${widget.id} does not exist in the database.', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () => context.read<JobCardProvider>().fetchJobCard(widget.id),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final jobCard = provider.currentJobCard!;

    final customerName = jobCard.customer?.name ?? 'Customer';
    final customerPhone = jobCard.customer?.phone ?? '';
    final vehicleModel = '${jobCard.vehicle?.brand ?? ''} ${jobCard.vehicle?.model ?? ''}'.trim().isEmpty
        ? 'Vehicle'
        : '${jobCard.vehicle?.brand ?? ''} ${jobCard.vehicle?.model ?? ''}'.trim();
    final vehicleNumber = jobCard.vehicle?.vehicleNumber ?? '';
    final status = jobCard.status;
    final items = jobCard.items;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('JOB-2025-${widget.id.toString().padLeft(6, '0')}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 12, bottom: 12),
            child: StatusBadge(
              status: status,
              fontSize: 12,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Remove Job Card',
            onPressed: () => _confirmDeleteJobCard(jobCard),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Customer & Vehicle Details Row (Side by Side)
          Row(
            children: [
              Expanded(
                child: Card(
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Customer', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(customerPhone.isNotEmpty ? customerPhone : 'No Phone', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Vehicle', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(vehicleModel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(vehicleNumber.isNotEmpty ? vehicleNumber : 'No Reg #', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Customer Notes (if present)
          if (jobCard.notes != null && jobCard.notes!.trim().isNotEmpty) ...[
            Card(
              color: const Color(0xFFFEF9C3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: const Color(0xFFFDE047).withValues(alpha: 0.8)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.sticky_note_2_outlined, color: Color(0xFFA16207), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer Note / Instructions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFFA16207),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            jobCard.notes!.trim(),
                            style: const TextStyle(
                              color: Color(0xFF713F12),
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Customer Request & Service Items
          const Text('Job Items & Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Card(
            color: AppColors.surface,
            child: items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No items added to this job card yet.', style: TextStyle(color: AppColors.textSecondary)),
                  )
                : Column(
                    children: items.map((item) {
                      final isExtraWork = item.type == 'repair' || item.type == 'part' || item.flag != 'none';
                      final isLastItem  = items.length == 1; // hide remove on last item
                      final isDeleting  = _deletingItemIds.contains(item.id);

                      final content = ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text('✓ ${item.description}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            ),
                            if (isExtraWork)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(left: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.extraWorkBg,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.extraWork.withValues(alpha: 0.3)),
                                ),
                                child: const Text('Extra Work', style: TextStyle(color: AppColors.extraWork, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        subtitle: Text(item.type.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(width: 8),
                            if (isDeleting)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                              )
                            else if (!isLastItem)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                tooltip: 'Remove Item',
                                onPressed: () async {
                                  // Show confirmation before removing
                                  final confirmed = await showModalBottomSheet<bool>(
                                    context: context,
                                    backgroundColor: AppColors.surface,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                    ),
                                    builder: (_) => Padding(
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
                                            child: Icon(Icons.delete_outline, color: AppColors.error, size: 30),
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Remove Item?',
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Remove "${item.description}" from this job card?\nThis cannot be undone.',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                                                  onPressed: () => Navigator.pop(context, false),
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
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text('Remove', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );

                                  if (confirmed == true && context.mounted) {
                                    setState(() => _deletingItemIds.add(item.id));
                                    try {
                                      await JobCardService.deleteItem(item.id);
                                      if (context.mounted) {
                                        await context.read<JobCardProvider>().fetchJobCard(widget.id, silent: true);
                                        Fluttertoast.showToast(msg: 'Removed ${item.description}');
                                      }
                                    } catch (e) {
                                      Fluttertoast.showToast(msg: 'Error removing item');
                                    } finally {
                                      if (mounted) {
                                        setState(() => _deletingItemIds.remove(item.id));
                                      }
                                    }
                                  }
                                },
                              ),
                          ],
                        ),
                      );

                      return isDeleting ? Opacity(opacity: 0.4, child: content) : content;
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 12),

          // Total Amount Summary
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textSecondary)),
                  Text(
                    '₹${(jobCard.finalTotal > 0 ? jobCard.finalTotal : items.fold<double>(0.0, (sum, i) => sum + i.price)).toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          if (status == 'completed') ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.receipt_long, color: Colors.white),
                label: const Text('Generate Invoice', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => context.push('/invoice/${widget.id}'),
              ),
            ),
          ] else ...[
            // Button 1: Start Work (If new)
            if (status == 'new') ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  onPressed: _updatingStatus
                      ? null
                      : () => _updateStatus(jobCard, 'in_progress'),
                  child: _updatingStatus
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Start Work ▶', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Button 2: Add Extra Work
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add, color: AppColors.primary),
                label: const Text('Add Extra Work', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showAddExtraWorkSheet(jobCard),
              ),
            ),
            const SizedBox(height: 12),

            // Button 3: Complete Job
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: _updatingStatus
                    ? null
                    : () => _updateStatus(jobCard, 'completed'),
                child: _updatingStatus
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Complete Job ✓', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),

            // Button 4: Remove Job Card
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                label: const Text('Remove Job Card', style: TextStyle(color: AppColors.error, fontSize: 15, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _confirmDeleteJobCard(jobCard),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildJobCardSkeleton() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('JOB-2025-${widget.id.toString().padLeft(6, '0')}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16, top: 14, bottom: 14),
            child: SkeletonBox(width: 85, height: 20, borderRadius: BorderRadius.all(Radius.circular(6))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: const [
              Expanded(
                child: Card(
                  color: AppColors.surface,
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 60, height: 11),
                        SizedBox(height: 6),
                        SkeletonBox(width: 100, height: 14),
                        SizedBox(height: 4),
                        SkeletonBox(width: 80, height: 12),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Card(
                  color: AppColors.surface,
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 50, height: 11),
                        SizedBox(height: 6),
                        SkeletonBox(width: 90, height: 14),
                        SizedBox(height: 4),
                        SkeletonBox(width: 75, height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const SkeletonBox(width: 140, height: 16),
          const SizedBox(height: 8),
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: List.generate(
                  3,
                  (i) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SkeletonBox(width: 16, height: 16),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(width: 130, height: 14),
                              SizedBox(height: 4),
                              SkeletonBox(width: 50, height: 10),
                            ],
                          ),
                        ),
                        SkeletonBox(width: 45, height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            color: AppColors.surface,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 100, height: 18),
                  SkeletonBox(width: 70, height: 26),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SkeletonBox(width: double.infinity, height: 50, borderRadius: BorderRadius.all(Radius.circular(12))),
        ],
      ),
    );
  }
}
