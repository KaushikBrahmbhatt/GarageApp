import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/customer.dart';
import '../../models/vehicle.dart';
import '../../services/customer_service.dart';
import '../../services/vehicle_service.dart';
import '../../providers/auth_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NewJobScreen extends StatefulWidget {
  const NewJobScreen({super.key});

  @override
  State<NewJobScreen> createState() => _NewJobScreenState();
}

class _NewJobScreenState extends State<NewJobScreen> {
  int _currentStep = 0; // 0 = Find Customer, 1 = Select Vehicle, 2 = Select Work
  Customer? _selectedCustomer;
  Vehicle? _selectedVehicle;

  // Search & Recent Customers
  final _searchCtrl = TextEditingController();
  List<Customer> _customers = [];
  bool _isLoading = false;

  // New Customer Form Controllers
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // New Vehicle Form Controllers
  final _vehicleNumberCtrl = TextEditingController();
  final _brandCtrl  = TextEditingController();
  final _modelCtrl  = TextEditingController();
  final _colorCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRecentCustomers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  String get _token => context.read<AuthProvider>().token ?? '';

  Future<void> _fetchRecentCustomers([String q = '']) async {
    setState(() => _isLoading = true);
    try {
      final results = await CustomerService.search(_token, q);
      setState(() => _customers = results);
    } catch (e) {
      // Fallback sample customers matching blueprint if offline/demo
      if (_customers.isEmpty) {
        setState(() {
          _customers = [
            Customer(id: 1, name: 'Rahul Sharma', phone: '9876543210', vehicles: [
              Vehicle(id: 101, vehicleNumber: 'MH 12 AB 1234', brand: 'Honda', model: 'Activa 6G'),
              Vehicle(id: 102, vehicleNumber: 'MH 12 XY 5678', brand: 'Honda', model: 'Shine'),
            ]),
            Customer(id: 2, name: 'Amit Patel', phone: '9876512340', vehicles: [
              Vehicle(id: 103, vehicleNumber: 'MH 12 PQ 9012', brand: 'TVS', model: 'Jupiter'),
            ]),
            Customer(id: 3, name: 'Vijay Joshi', phone: '9812345678', vehicles: [
              Vehicle(id: 102, vehicleNumber: 'MH 12 XY 5678', brand: 'Honda', model: 'Shine'),
            ]),
            Customer(id: 4, name: 'Suresh Kumar', phone: '9821122334', vehicles: []),
            Customer(id: 5, name: 'Pooja Singh', phone: '9765432190', vehicles: []),
          ];
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddCustomerSheet() {
    _nameCtrl.text = _searchCtrl.text.contains(RegExp(r'[0-9]')) ? '' : _searchCtrl.text;
    _phoneCtrl.text = _searchCtrl.text.contains(RegExp(r'[0-9]')) ? _searchCtrl.text : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Customer Name *', hintText: 'e.g. Rahul Sharma'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile Number *', hintText: 'e.g. 9876543210'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
                    Fluttertoast.showToast(msg: 'Name and Phone Number are required');
                    return;
                  }
                  try {
                    final c = await CustomerService.create(_token, _nameCtrl.text.trim(), _phoneCtrl.text.trim(), '');
                    setState(() {
                      _selectedCustomer = c;
                      _currentStep = 1;
                    });
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    // Local fallback
                    final c = Customer(id: DateTime.now().millisecondsSinceEpoch, name: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim(), vehicles: []);
                    setState(() {
                      _customers.insert(0, c);
                      _selectedCustomer = c;
                      _currentStep = 1;
                    });
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Save Customer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAddVehicleSheet() {
    _vehicleNumberCtrl.clear();
    _brandCtrl.clear();
    _modelCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Vehicle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: _vehicleNumberCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Vehicle Number *', hintText: 'e.g. MH 12 AB 1234'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _brandCtrl,
              decoration: const InputDecoration(labelText: 'Brand', hintText: 'e.g. Honda'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _modelCtrl,
              decoration: const InputDecoration(labelText: 'Model', hintText: 'e.g. Activa 6G'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  if (_vehicleNumberCtrl.text.trim().isEmpty) {
                    Fluttertoast.showToast(msg: 'Vehicle Number is required');
                    return;
                  }
                  final number = _vehicleNumberCtrl.text.trim().toUpperCase();
                  final brand = _brandCtrl.text.trim();
                  final model = _modelCtrl.text.trim();

                  try {
                    final v = await VehicleService.create(_token, _selectedCustomer!.id, number, brand, model, '');
                    setState(() {
                      _selectedVehicle = v;
                      if (!_selectedCustomer!.vehicles.any((x) => x.id == v.id)) {
                        _selectedCustomer!.vehicles.add(v);
                      }
                    });
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    // Local fallback
                    final v = Vehicle(id: DateTime.now().millisecondsSinceEpoch, vehicleNumber: number, brand: brand, model: model);
                    setState(() {
                      _selectedCustomer!.vehicles.add(v);
                      _selectedVehicle = v;
                    });
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Save & Attach Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          _currentStep == 0 ? 'Find Customer' : (_currentStep == 1 ? 'Select Vehicle' : 'What Customer Wants'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _currentStep == 0 ? _buildFindCustomerStep() : _buildSelectVehicleStep(),
    );
  }

  // ── Step 1: Find Customer Screen ───────────────────────────────────────────
  Widget _buildFindCustomerStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by name or mobile',
              hintStyle: const TextStyle(color: AppColors.textLight),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.cardBorder)),
            ),
            onChanged: (q) => _fetchRecentCustomers(q),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Recent Customers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _customers.length,
                  itemBuilder: (context, index) {
                    final c = _customers[index];
                    final isSelected = _selectedCustomer?.id == c.id;
                    return Card(
                      color: isSelected ? AppColors.primaryLight : AppColors.surface,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.cardBorder, width: isSelected ? 2 : 1),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? AppColors.primary : AppColors.background,
                          child: Icon(Icons.person, color: isSelected ? Colors.white : AppColors.textSecondary),
                        ),
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        subtitle: Text(c.phone, style: const TextStyle(color: AppColors.textSecondary)),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : const Icon(Icons.chevron_right, color: AppColors.textLight),
                        onTap: () {
                          setState(() {
                            _selectedCustomer = c;
                            _currentStep = 1;
                          });
                        },
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('+ New Customer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _showAddCustomerSheet,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Select / Add Vehicle Screen ───────────────────────────────────
  Widget _buildSelectVehicleStep() {
    return Column(
      children: [
        // Selected Customer Summary Banner
        if (_selectedCustomer != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selected Customer', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_selectedCustomer!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary)),
                Text(_selectedCustomer!.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Select Vehicle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: (_selectedCustomer?.vehicles ?? []).isEmpty
              ? Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.two_wheeler, color: AppColors.textLight, size: 48),
                      SizedBox(height: 12),
                      Text('No vehicles attached to this customer yet.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('Tap "+ Add Vehicle" below to attach a bike/scooter.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _selectedCustomer!.vehicles.length,
                  itemBuilder: (context, index) {
                    final v = _selectedCustomer!.vehicles[index];
                    final isSelected = _selectedVehicle?.id == v.id;
                    return Card(
                      color: isSelected ? AppColors.primaryLight : AppColors.surface,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.cardBorder, width: isSelected ? 2 : 1),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? AppColors.primary : AppColors.background,
                          child: Icon(Icons.two_wheeler, color: isSelected ? Colors.white : AppColors.primary),
                        ),
                        title: Text(
                          '${v.brand ?? ''} ${v.model ?? ''}'.trim().isNotEmpty ? '${v.brand ?? ''} ${v.model ?? ''}'.trim() : 'Vehicle',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        subtitle: Text(v.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        trailing: Radio<int>(
                          value: v.id,
                          groupValue: _selectedVehicle?.id,
                          activeColor: AppColors.primary,
                          onChanged: (_) {
                            setState(() => _selectedVehicle = v);
                          },
                        ),
                        onTap: () {
                          setState(() => _selectedVehicle = v);
                        },
                      ),
                    );
                  },
                ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    label: const Text('+ Add Vehicle', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _showAddVehicleSheet,
                  ),
                ),
                if (_selectedVehicle != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Fluttertoast.showToast(msg: 'Customer & Vehicle Selected: ${_selectedCustomer!.name} (${_selectedVehicle!.vehicleNumber})');
                      },
                      child: const Text('Continue to Select Work →', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
