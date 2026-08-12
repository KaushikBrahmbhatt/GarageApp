import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/customer.dart';
import '../../models/vehicle.dart';
import '../../models/job_card.dart';
import '../../services/customer_service.dart';
import '../../services/vehicle_service.dart';
import '../../providers/auth_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  List<Customer> _results = [];
  bool _isSearching = false;
  String? _error;

  String get _token => context.read<AuthProvider>().token ?? '';

  Future<void> _search(String q) async {
    if (q.length < 3) { setState(() { _results = []; _error = null; }); return; }
    setState(() { _isSearching = true; _error = null; });
    try {
      final list = await CustomerService.search(_token, q);
      setState(() => _results = list);
    } catch (e) {
      setState(() => _error = 'Search failed. Check connection.');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(title: const Text('Search History'), backgroundColor: AppTheme.kSurface),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppTheme.kTextPrimary),
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search by name or phone number...',
                hintStyle: const TextStyle(color: AppTheme.kTextMuted),
                prefixIcon: _isSearching
                    ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.kPrimary)))
                    : const Icon(Icons.search, color: AppTheme.kTextMuted),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.kTextMuted), onPressed: () { _searchCtrl.clear(); setState(() => _results = []); })
                    : null,
                filled: true, fillColor: AppTheme.kCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          if (_error != null)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(_error!, style: const TextStyle(color: AppTheme.kError))),
          if (_results.isEmpty && _searchCtrl.text.length >= 3 && !_isSearching)
            const Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.search_off, size: 64, color: AppTheme.kTextMuted),
              SizedBox(height: 12),
              Text('No customers found', style: TextStyle(color: AppTheme.kTextMuted)),
            ]))),
          if (_searchCtrl.text.length < 3)
            const Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.history, size: 64, color: AppTheme.kTextMuted),
              SizedBox(height: 12),
              Text('Type at least 3 characters to search', style: TextStyle(color: AppTheme.kTextMuted)),
            ]))),
          if (_results.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _results.length,
                itemBuilder: (_, i) => _CustomerCard(customer: _results[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatefulWidget {
  final Customer customer;
  const _CustomerCard({required this.customer});
  @override State<_CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<_CustomerCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppTheme.kCard, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(backgroundColor: AppTheme.kPrimary, child: Icon(Icons.person, color: Colors.white)),
            title: Text(c.name, style: const TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold)),
            subtitle: Text(c.phone, style: const TextStyle(color: AppTheme.kTextMuted)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('${c.vehicles.length} vehicle(s)', style: const TextStyle(color: AppTheme.kTextMuted, fontSize: 12)),
              const SizedBox(width: 4),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.kPrimary),
            ]),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            ...c.vehicles.map((v) => _VehicleRow(vehicle: v)),
        ],
      ),
    );
  }
}

class _VehicleRow extends StatefulWidget {
  final Vehicle vehicle;
  const _VehicleRow({required this.vehicle});
  @override State<_VehicleRow> createState() => _VehicleRowState();
}

class _VehicleRowState extends State<_VehicleRow> {
  List<JobCard>? _history;
  bool _loading = false;
  bool _expanded = false;
  String get _token => context.read<AuthProvider>().token ?? '';

  Future<void> _loadHistory() async {
    if (_history != null) { setState(() => _expanded = !_expanded); return; }
    setState(() { _loading = true; _expanded = true; });
    try {
      final list = await VehicleService.history(_token, widget.vehicle.id);
      setState(() => _history = list);
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
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
    final v = widget.vehicle;
    return Column(
      children: [
        const Divider(height: 1, color: AppTheme.kSurface, indent: 16, endIndent: 16),
        ListTile(
          contentPadding: const EdgeInsets.only(left: 32, right: 16),
          leading: const Icon(Icons.two_wheeler, color: AppTheme.kPrimary),
          title: Text(v.vehicleNumber, style: const TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold)),
          subtitle: Text('${v.brand ?? ''} ${v.model ?? ''}'.trim(), style: const TextStyle(color: AppTheme.kTextMuted, fontSize: 12)),
          trailing: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.kPrimary))
              : Icon(_expanded ? Icons.expand_less : Icons.chevron_right, color: AppTheme.kPrimary),
          onTap: _loadHistory,
        ),
        if (_expanded && _history != null)
          ..._history!.map((jc) => Container(
            margin: const EdgeInsets.only(left: 48, right: 16, bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.kSurface, borderRadius: BorderRadius.circular(10)),
            child: InkWell(
              onTap: () => context.push('/job-card/${jc.id}'),
              child: Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _statusColor(jc.status)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Job #${jc.id} · ${jc.items.length} item(s)', style: const TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
                  Text(DateFormat('dd MMM yyyy').format(jc.createdAt.toLocal()), style: const TextStyle(color: AppTheme.kTextMuted, fontSize: 12)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('₹${jc.finalTotal.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.kPrimary, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: _statusColor(jc.status).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(jc.status.replaceAll('_', ' '), style: TextStyle(color: _statusColor(jc.status), fontSize: 10)),
                  ),
                ]),
              ]),
            ),
          )),
        if (_expanded && _history?.isEmpty == true)
          const Padding(
            padding: EdgeInsets.only(left: 48, bottom: 12),
            child: Text('No job history for this vehicle', style: TextStyle(color: AppTheme.kTextMuted, fontSize: 12)),
          ),
      ],
    );
  }
}
