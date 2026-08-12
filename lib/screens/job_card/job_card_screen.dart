import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/job_card.dart';
import '../../models/job_card_item.dart';
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

  final List<String> _statuses = ['new', 'in_progress', 'waiting_confirmation', 'completed'];
  final Map<String, String> _statusLabels = {
    'new': 'New',
    'in_progress': 'In Progress',
    'waiting_confirmation': 'Awaiting',
    'completed': 'Completed',
  };

  Color _statusColor(String status) {
    switch (status) {
      case 'new': return Colors.grey;
      case 'in_progress': return AppTheme.kPrimary;
      case 'waiting_confirmation': return AppTheme.kWarning;
      case 'completed': return AppTheme.kSuccess;
      default: return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'repair': return Icons.build;
      case 'service': return Icons.settings;
      case 'oil': return Icons.opacity;
      case 'part': return Icons.extension;
      default: return Icons.more_horiz;
    }
  }

  Color _flagColor(String flag) {
    switch (flag) {
      case 'needs_inspection': return AppTheme.kWarning;
      case 'needs_confirmation': return Colors.blue;
      case 'confirmed': return AppTheme.kSuccess;
      default: return Colors.transparent;
    }
  }

  String _flagLabel(String flag) {
    switch (flag) {
      case 'needs_inspection': return '🟡 Needs Inspection';
      case 'needs_confirmation': return '🔵 Needs Confirmation';
      case 'confirmed': return '✅ Confirmed';
      default: return '';
    }
  }

  Future<void> _advanceStatus(JobCard jobCard) async {
    final currentIndex = _statuses.indexOf(jobCard.status);
    if (currentIndex >= _statuses.length - 1) return;
    final nextStatus = _statuses[currentIndex + 1];
    setState(() => _updatingStatus = true);
    try {
      await JobCardService.updateStatus(jobCard.id, nextStatus);
      if (mounted) context.read<JobCardProvider>().fetchJobCard(widget.id);
      Fluttertoast.showToast(msg: 'Status updated to ${_statusLabels[nextStatus]}');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => _updatingStatus = false);
    }
  }

  Future<void> _deleteItem(int itemId) async {
    try {
      await JobCardService.deleteItem(itemId);
      if (mounted) context.read<JobCardProvider>().fetchJobCard(widget.id);
      Fluttertoast.showToast(msg: 'Item removed');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  void _showAddItemSheet(int jobCardId) {
    String type = 'repair';
    String flag = 'none';
    final descCtrl  = TextEditingController();
    final priceCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Add Item', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(color: AppTheme.kTextPrimary)),
          const SizedBox(height: 16),
          const Text('Type', style: TextStyle(color: AppTheme.kTextMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: ['repair', 'service', 'oil', 'part', 'other'].map((t) => ChoiceChip(
            label: Text(t[0].toUpperCase() + t.substring(1)),
            selected: type == t,
            selectedColor: AppTheme.kPrimary,
            onSelected: (_) => setSheetState(() => type = t),
          )).toList()),
          const SizedBox(height: 12),
          _buildField(descCtrl, 'Description *'),
          const SizedBox(height: 12),
          _buildField(priceCtrl, 'Price (₹) *', keyboard: TextInputType.number),
          const SizedBox(height: 12),
          const Text('Flag', style: TextStyle(color: AppTheme.kTextMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('None'), selected: flag == 'none', onSelected: (_) => setSheetState(() => flag = 'none')),
            ChoiceChip(label: const Text('🟡 Inspection'), selected: flag == 'needs_inspection', selectedColor: AppTheme.kWarning, onSelected: (_) => setSheetState(() => flag = 'needs_inspection')),
            ChoiceChip(label: const Text('🔵 Confirm'), selected: flag == 'needs_confirmation', selectedColor: Colors.blue, onSelected: (_) => setSheetState(() => flag = 'needs_confirmation')),
          ]),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                if (descCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await JobCardService.addItem(jobCardId, {'type': type, 'description': descCtrl.text.trim(), 'price': double.tryParse(priceCtrl.text) ?? 0, 'flag': flag});
                  if (mounted) context.read<JobCardProvider>().fetchJobCard(widget.id);
                  Fluttertoast.showToast(msg: 'Item added');
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Error: $e');
                }
              },
              child: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      )),
    );
  }

  TextField _buildField(TextEditingController ctrl, String label, {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: AppTheme.kTextPrimary),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: AppTheme.kTextMuted),
        filled: true, fillColor: AppTheme.kSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobCardProvider>();
    final jobCard = provider.currentJobCard;

    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: Text('Job Card #${widget.id}'),
        backgroundColor: AppTheme.kSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<JobCardProvider>().fetchJobCard(widget.id),
          ),
        ],
      ),
      body: provider.isLoading || jobCard == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.kPrimary))
          : RefreshIndicator(
              color: AppTheme.kPrimary,
              onRefresh: () => context.read<JobCardProvider>().fetchJobCard(widget.id),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Customer + Vehicle Card ─────────────────────────
                  _sectionCard(children: [
                    Row(children: [
                      const CircleAvatar(backgroundColor: AppTheme.kPrimary, child: Icon(Icons.person, color: Colors.white)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(jobCard.customer?.name ?? 'Unknown',
                            style: const TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(jobCard.customer?.phone ?? '',
                            style: const TextStyle(color: AppTheme.kTextMuted)),
                      ])),
                    ]),
                    const Divider(height: 20, color: AppTheme.kSurface),
                    Row(children: [
                      const Icon(Icons.two_wheeler, color: AppTheme.kPrimary),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(jobCard.vehicle?.vehicleNumber ?? '',
                            style: const TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('${jobCard.vehicle?.brand ?? ''} ${jobCard.vehicle?.model ?? ''}'.trim(),
                            style: const TextStyle(color: AppTheme.kTextMuted)),
                      ]),
                    ]),
                  ]),

                  const SizedBox(height: 12),

                  // ── Status Stepper ──────────────────────────────────
                  _sectionCard(children: [
                    const Text('Status', style: TextStyle(color: AppTheme.kTextMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(children: _statuses.asMap().entries.map((e) {
                      final idx = e.key;
                      final s = e.value;
                      final current = _statuses.indexOf(jobCard.status);
                      final isActive = idx <= current;
                      final isLast = idx == _statuses.length - 1;
                      return Expanded(child: Row(children: [
                        Expanded(child: Column(children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? _statusColor(s) : AppTheme.kSurface,
                            ),
                            child: Icon(isActive ? Icons.check : Icons.circle, color: Colors.white, size: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(_statusLabels[s]!, style: TextStyle(color: isActive ? _statusColor(s) : AppTheme.kTextMuted, fontSize: 10), textAlign: TextAlign.center),
                        ])),
                        if (!isLast) Expanded(child: Container(height: 2, color: idx < current ? AppTheme.kPrimary : AppTheme.kSurface)),
                      ]));
                    }).toList()),
                    const SizedBox(height: 12),
                    if (jobCard.status != 'completed')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: _updatingStatus ? null : () => _advanceStatus(jobCard),
                          child: _updatingStatus
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  'Move to ${_statusLabels[_statuses[_statuses.indexOf(jobCard.status) + 1]]}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                  ]),

                  const SizedBox(height: 12),

                  // ── Items ───────────────────────────────────────────
                  _sectionCard(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Items', style: TextStyle(color: AppTheme.kTextMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, color: AppTheme.kPrimary, size: 16),
                        label: const Text('Add', style: TextStyle(color: AppTheme.kPrimary)),
                        onPressed: () => _showAddItemSheet(jobCard.id),
                      ),
                    ]),
                    if (jobCard.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: Text('No items yet', style: TextStyle(color: AppTheme.kTextMuted))),
                      ),
                    ...jobCard.items.map((item) => _ItemTile(
                      item: item,
                      typeIcon: _typeIcon(item.type),
                      flagColor: _flagColor(item.flag),
                      flagLabel: _flagLabel(item.flag),
                      onDelete: () => _deleteItem(item.id),
                    )),
                  ]),

                  const SizedBox(height: 12),

                  // ── Totals ──────────────────────────────────────────
                  _sectionCard(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Estimated', style: TextStyle(color: AppTheme.kTextMuted)),
                      Text('₹${jobCard.estimatedTotal.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Final Total', style: TextStyle(color: AppTheme.kTextMuted)),
                      Text('₹${jobCard.finalTotal.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.kPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
                    ]),
                  ]),

                  const SizedBox(height: 16),

                  // ── Invoice Button ──────────────────────────────────
                  if (jobCard.status == 'completed')
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.kSuccess,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.receipt_long, color: Colors.white),
                        label: const Text('Generate Invoice', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () => context.push('/invoice/${widget.id}'),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.kCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final JobCardItem item;
  final IconData typeIcon;
  final Color flagColor;
  final String flagLabel;
  final VoidCallback onDelete;

  const _ItemTile({required this.item, required this.typeIcon, required this.flagColor, required this.flagLabel, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.kSurface, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.kPrimary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(typeIcon, color: AppTheme.kPrimary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.description, style: const TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(item.type[0].toUpperCase() + item.type.substring(1), style: const TextStyle(color: AppTheme.kTextMuted, fontSize: 12)),
          if (item.flag != 'none')
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: flagColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              child: Text(flagLabel, style: TextStyle(color: flagColor, fontSize: 11)),
            ),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.kPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
          IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.delete_outline, color: AppTheme.kError, size: 18), onPressed: onDelete),
        ]),
      ]),
    );
  }
}
