import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/vehicle.dart';
import '../../services/customer_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final _searchCtrl = TextEditingController();
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }



  Future<void> _fetchVehicles([String q = '']) async {
    setState(() => _isLoading = true);
    try {
      final customers = await CustomerService.search('');
      final List<Vehicle> allVehicles = [];
      for (final c in customers) {
        allVehicles.addAll(c.vehicles);
      }
      // Remove duplicate vehicle IDs
      final Map<int, Vehicle> unique = {};
      for (final v in allVehicles) {
        unique[v.id] = v;
      }
      final list = unique.values.toList();
      if (q.isNotEmpty) {
        setState(() {
          _vehicles = list.where((v) =>
            v.vehicleNumber.toLowerCase().contains(q.toLowerCase()) ||
            (v.model ?? '').toLowerCase().contains(q.toLowerCase()) ||
            (v.brand ?? '').toLowerCase().contains(q.toLowerCase())
          ).toList();
        });
      } else {
        setState(() => _vehicles = list);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error loading vehicles');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vehicles', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by registration or model',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
              ),
              onChanged: (q) => _fetchVehicles(q),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _vehicles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.two_wheeler, color: AppColors.textLight, size: 48),
                            SizedBox(height: 12),
                            Text('No vehicles found.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _vehicles.length,
                        itemBuilder: (context, index) {
                          final v = _vehicles[index];
                          return Card(
                            color: AppColors.surface,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Icon(Icons.two_wheeler, color: AppColors.primary),
                              ),
                              title: Text(
                                '${v.brand ?? ''} ${v.model ?? ''}'.trim().isNotEmpty ? '${v.brand ?? ''} ${v.model ?? ''}'.trim() : 'Vehicle',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              subtitle: Text(v.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
