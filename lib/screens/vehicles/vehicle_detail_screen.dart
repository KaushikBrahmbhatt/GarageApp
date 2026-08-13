import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/rpm_gauge_loader.dart';

class VehicleDetailScreen extends StatefulWidget {
  final int id;
  const VehicleDetailScreen({super.key, required this.id});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  Vehicle? _vehicle;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicle();
  }

  Future<void> _fetchVehicle() async {
    setState(() => _loading = true);
    try {
      final res = await VehicleService.get(widget.id);
      if (mounted) {
        setState(() {
          _vehicle = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        Fluttertoast.showToast(msg: 'Failed to load vehicle details');
      }
    }
  }

  void _showEditVehicleSheet() {
    if (_vehicle == null) return;
    final numberCtrl = TextEditingController(text: _vehicle!.vehicleNumber);
    final brandCtrl = TextEditingController(text: _vehicle!.brand ?? '');
    final modelCtrl = TextEditingController(text: _vehicle!.model ?? '');
    final colorCtrl = TextEditingController(text: _vehicle!.color ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Vehicle Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: numberCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Registration Number *'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Model'))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: colorCtrl,
              decoration: const InputDecoration(labelText: 'Color'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  if (numberCtrl.text.trim().isEmpty) {
                    Fluttertoast.showToast(msg: 'Please enter registration number');
                    return;
                  }
                  Navigator.pop(ctx);
                  RpmGaugeLoader.show(context, statusMessages: ['Updating vehicle details', 'Saving changes', 'Almost ready']);
                  try {
                    await VehicleService.update(
                      _vehicle!.id,
                      numberCtrl.text.trim(),
                      brandCtrl.text.trim().isEmpty ? null : brandCtrl.text.trim(),
                      modelCtrl.text.trim().isEmpty ? null : modelCtrl.text.trim(),
                      colorCtrl.text.trim().isEmpty ? null : colorCtrl.text.trim(),
                    );
                    if (mounted) {
                      RpmGaugeLoader.hide(context);
                      Fluttertoast.showToast(msg: 'Vehicle details updated');
                      _fetchVehicle();
                    }
                  } catch (e) {
                    if (mounted) RpmGaugeLoader.hide(context);
                    Fluttertoast.showToast(msg: 'Failed to update vehicle: $e');
                  }
                },
                child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Vehicle Details'), backgroundColor: AppColors.surface),
        body: const Padding(
          padding: EdgeInsets.all(16.0),
          child: SkeletonListLoader(count: 3),
        ),
      );
    }

    if (_vehicle == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Vehicle Details'), backgroundColor: AppColors.surface),
        body: const Center(child: Text('Vehicle not found', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    final v = _vehicle!;
    final totalSpend = v.jobCards.fold<double>(0, (sum, jc) => sum + jc.finalTotal);
    final modelName = '${v.brand ?? ''} ${v.model ?? ''}'.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(v.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: 'Edit Vehicle',
            onPressed: _showEditVehicleSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchVehicle,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Vehicle Header Card
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.two_wheeler, size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(v.vehicleNumber, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      modelName.isNotEmpty ? modelName : 'Two Wheeler',
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    if (v.color != null && v.color!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Color: ${v.color}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('${v.jobCards.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            const SizedBox(height: 2),
                            const Text('Service Visits', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        Container(height: 30, width: 1, color: AppColors.cardBorder),
                        Column(
                          children: [
                            Text('₹${totalSpend.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.successText)),
                            const SizedBox(height: 2),
                            const Text('Total Spent', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Owner Information
            if (v.customer != null) ...[
              const Text('Owner Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Card(
                color: AppColors.surface,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.person, color: AppColors.primary, size: 22),
                  ),
                  title: Text(v.customer!.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  subtitle: Text(v.customer!.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: () => context.push('/customer/${v.customer!.id}'),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Service History
            const Text('Vehicle Service Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            if (v.jobCards.isEmpty)
              const Card(
                color: AppColors.surface,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('No service records found for this vehicle.', style: TextStyle(color: AppColors.textSecondary))),
                ),
              )
            else
              ...v.jobCards.map((jc) {
                final itemsSummary = jc.items.take(2).map((i) => i.description).join(', ');
                final moreCount = jc.items.length > 2 ? ' +${jc.items.length - 2} more' : '';

                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.build, color: AppColors.primary, size: 20),
                    ),
                    title: Text('JOB-${jc.createdAt.year}-${jc.id.toString().padLeft(6, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemsSummary.isNotEmpty ? '$itemsSummary$moreCount' : 'General Service',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                  ),
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
