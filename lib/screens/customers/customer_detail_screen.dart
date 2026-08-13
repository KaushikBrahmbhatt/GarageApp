import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/app_colors.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import '../../services/vehicle_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/rpm_gauge_loader.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int id;
  const CustomerDetailScreen({super.key, required this.id});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Customer? _customer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomer();
  }

  Future<void> _fetchCustomer() async {
    setState(() => _loading = true);
    try {
      final res = await CustomerService.get(widget.id);
      if (mounted) {
        setState(() {
          _customer = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        Fluttertoast.showToast(msg: 'Failed to load customer details');
      }
    }
  }

  void _showEditCustomerSheet() {
    if (_customer == null) return;
    final nameCtrl = TextEditingController(text: _customer!.name);
    final phoneCtrl = TextEditingController(text: _customer!.phone);
    final emailCtrl = TextEditingController(text: _customer!.email ?? '');

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
            const Text('Edit Customer Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Customer Name *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email Address (Optional)'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                    Fluttertoast.showToast(msg: 'Please fill name and phone');
                    return;
                  }
                  Navigator.pop(ctx);
                  RpmGaugeLoader.show(context, statusMessages: ['Updating customer details', 'Saving changes', 'Almost ready']);
                  try {
                    await CustomerService.update(
                      _customer!.id,
                      nameCtrl.text.trim(),
                      phoneCtrl.text.trim(),
                      emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    );
                    if (mounted) {
                      RpmGaugeLoader.hide(context);
                      Fluttertoast.showToast(msg: 'Customer updated successfully');
                      _fetchCustomer();
                    }
                  } catch (e) {
                    if (mounted) RpmGaugeLoader.hide(context);
                    Fluttertoast.showToast(msg: 'Failed to update customer: $e');
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

  void _showAddVehicleSheet() {
    if (_customer == null) return;
    final numberCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final colorCtrl = TextEditingController();

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
            const Text('Add Vehicle for Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: numberCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Vehicle Reg # (e.g. MH 12 AB 1234) *'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand (e.g. Honda)'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Model (e.g. Activa 6G)'))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: colorCtrl,
              decoration: const InputDecoration(labelText: 'Color (Optional)'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  if (numberCtrl.text.trim().isEmpty) {
                    Fluttertoast.showToast(msg: 'Please enter vehicle registration number');
                    return;
                  }
                  Navigator.pop(ctx);
                  RpmGaugeLoader.show(context, statusMessages: ['Adding vehicle', 'Linking to customer', 'Almost ready']);
                  try {
                    await VehicleService.create(
                      _customer!.id,
                      numberCtrl.text.trim(),
                      brandCtrl.text.trim().isEmpty ? null : brandCtrl.text.trim(),
                      modelCtrl.text.trim().isEmpty ? null : modelCtrl.text.trim(),
                      colorCtrl.text.trim().isEmpty ? null : colorCtrl.text.trim(),
                    );
                    if (mounted) {
                      RpmGaugeLoader.hide(context);
                      Fluttertoast.showToast(msg: 'Vehicle added successfully');
                      _fetchCustomer();
                    }
                  } catch (e) {
                    if (mounted) RpmGaugeLoader.hide(context);
                    Fluttertoast.showToast(msg: 'Failed to add vehicle: $e');
                  }
                },
                child: const Text('Add Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
        appBar: AppBar(title: const Text('Customer Profile'), backgroundColor: AppColors.surface),
        body: const Padding(
          padding: EdgeInsets.all(16.0),
          child: SkeletonListLoader(count: 4),
        ),
      );
    }

    if (_customer == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Customer Profile'), backgroundColor: AppColors.surface),
        body: const Center(child: Text('Customer not found', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    final c = _customer!;
    final totalSpend = c.jobCards.fold<double>(0, (sum, jc) => sum + jc.finalTotal);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: 'Edit Profile',
            onPressed: _showEditCustomerSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchCustomer,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Card
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(c.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(c.phone, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    if (c.email != null && c.email!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(c.email!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('${c.vehicles.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            const SizedBox(height: 2),
                            const Text('Vehicles', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        Container(height: 30, width: 1, color: AppColors.cardBorder),
                        Column(
                          children: [
                            Text('${c.jobCards.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            const SizedBox(height: 2),
                            const Text('Total Jobs', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        Container(height: 30, width: 1, color: AppColors.cardBorder),
                        Column(
                          children: [
                            Text('₹${totalSpend.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.successText)),
                            const SizedBox(height: 2),
                            const Text('Total Spend', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Vehicles Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Registered Vehicles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                TextButton.icon(
                  onPressed: _showAddVehicleSheet,
                  icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                  label: const Text('Add Vehicle', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (c.vehicles.isEmpty)
              const Card(
                color: AppColors.surface,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('No vehicles registered for this customer.', style: TextStyle(color: AppColors.textSecondary))),
                ),
              )
            else
              ...c.vehicles.map((v) {
                final modelName = '${v.brand ?? ''} ${v.model ?? ''}'.trim();
                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.two_wheeler, color: AppColors.primary, size: 22),
                    ),
                    title: Text(v.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    subtitle: Text(modelName.isNotEmpty ? modelName : 'Two Wheeler', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    onTap: () => context.push('/vehicle/${v.id}'),
                  ),
                );
              }),
            const SizedBox(height: 20),

            // Job Cards Service History
            const Text('Repair & Service History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            if (c.jobCards.isEmpty)
              const Card(
                color: AppColors.surface,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('No job history found for this customer.', style: TextStyle(color: AppColors.textSecondary))),
                ),
              )
            else
              ...c.jobCards.map((jc) {
                final vehicleModel = jc.vehicle != null ? '${jc.vehicle?.brand ?? ''} ${jc.vehicle?.model ?? ''}'.trim() : 'Vehicle';
                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.receipt_long, color: AppColors.primary, size: 22),
                    ),
                    title: Text('JOB-2025-${jc.id.toString().padLeft(6, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                    subtitle: Text('${jc.vehicle?.vehicleNumber ?? ''} • $vehicleModel', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
