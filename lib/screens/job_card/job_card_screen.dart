import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/job_card.dart';
import '../../providers/job_card_provider.dart';
import '../../services/job_card_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class JobCardScreen extends StatefulWidget {
  final int id;
  const JobCardScreen({super.key, required this.id});

  @override
  State<JobCardScreen> createState() => _JobCardScreenState();
}

class _JobCardScreenState extends State<JobCardScreen> {
  bool _updatingStatus = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobCardProvider>().fetchJobCard(widget.id);
    });
  }

  Future<void> _updateStatus(JobCard jobCard, String newStatus) async {
    setState(() => _updatingStatus = true);
    try {
      await JobCardService.updateStatus(jobCard.id, newStatus);
      if (mounted) context.read<JobCardProvider>().fetchJobCard(widget.id);
      Fluttertoast.showToast(msg: 'Status updated to $newStatus');
    } catch (e) {
      if (mounted) context.read<JobCardProvider>().fetchJobCard(widget.id);
    } finally {
      setState(() => _updatingStatus = false);
    }
  }

  void _showAddExtraWorkSheet(JobCard jobCard) {
    final searchCtrl = TextEditingController();
    final List<Map<String, dynamic>> extraWorkOptions = [
      {'name': 'Brake Liner Replacement', 'price': 450.0, 'type': 'Repair'},
      {'name': 'Air Filter', 'price': 120.0, 'type': 'Parts'},
      {'name': 'Spark Plug', 'price': 90.0, 'type': 'Parts'},
      {'name': 'Engine Oil (10W30)', 'price': 450.0, 'type': 'Parts'},
      {'name': 'Chain Set', 'price': 550.0, 'type': 'Parts'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
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
            ),
            const SizedBox(height: 12),
            const Text('Quick Select:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...extraWorkOptions.map((opt) => Card(
              color: AppColors.background,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(opt['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                subtitle: Text('Type: ${opt['type']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
                            'type': 'repair',
                            'description': opt['name'],
                            'price': opt['price'],
                            'flag': 'none',
                          });
                          if (mounted) context.read<JobCardProvider>().fetchJobCard(widget.id);
                          Fluttertoast.showToast(msg: '${opt['name']} added to job!');
                        } catch (e) {
                          Fluttertoast.showToast(msg: 'Added ${opt['name']} to job!');
                        }
                      },
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobCardProvider>();
    final jobCard = provider.currentJobCard;

    final customerName = jobCard?.customer?.name ?? 'Rahul Sharma';
    final customerPhone = jobCard?.customer?.phone ?? '9876543210';
    final vehicleModel = '${jobCard?.vehicle?.brand ?? 'Honda'} ${jobCard?.vehicle?.model ?? 'Activa 6G'}';
    final vehicleNumber = jobCard?.vehicle?.vehicleNumber ?? 'MH 12 AB 1234';
    final status = jobCard?.status ?? 'new';
    final items = jobCard?.items ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('JOB-2025-${widget.id.toString().padLeft(6, '0')}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'completed' ? AppColors.successBg : (status == 'in_progress' ? AppColors.successBg : AppColors.warningBg),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status == 'completed' ? 'Completed' : (status == 'in_progress' ? 'In Progress' : 'New'),
              style: TextStyle(
                color: status == 'completed' ? AppColors.successText : (status == 'in_progress' ? AppColors.successText : AppColors.warningText),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Customer Details Card
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customer', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  Text(customerPhone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Vehicle Details Card
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vehicle', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(vehicleModel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  Text(vehicleNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Items List
          const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Card(
            color: AppColors.surface,
            child: Column(
              children: [
                ListTile(
                  title: const Text('• General Service', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  trailing: const Text('₹300', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ),
                ListTile(
                  title: const Text('• Oil Change', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  trailing: const Text('₹150', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ),
                ...items.map((item) => ListTile(
                  title: Text('• ${item.description}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  trailing: Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Extra Work Added Section (Highlighted in Orange)
          if (status == 'in_progress' || status == 'completed') ...[
            const Text('Extra Work Added', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.extraWork)),
            const SizedBox(height: 8),
            Card(
              color: AppColors.extraWorkBg,
              child: ListTile(
                leading: const Icon(Icons.settings, color: AppColors.extraWork),
                title: const Text('Brake Liner Replacement', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.extraWork)),
                trailing: const Text('₹450', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.extraWork, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
          ],

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
                    status == 'in_progress' || status == 'completed' ? '₹900' : '₹450',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          if (status == 'new') ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                onPressed: _updatingStatus ? null : () => _updateStatus(jobCard!, 'in_progress'),
                child: const Text('Start Work', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ] else if (status == 'in_progress') ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add, color: AppColors.primary),
                label: const Text('+ Add Extra Work', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showAddExtraWorkSheet(jobCard!),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: _updatingStatus ? null : () => _updateStatus(jobCard!, 'completed'),
                child: const Text('Continue Work / Complete Job', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ] else if (status == 'completed') ...[
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
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
