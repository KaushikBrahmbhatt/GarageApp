import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/customer.dart';
import '../../models/vehicle.dart';
import '../../services/customer_service.dart';
import '../../services/vehicle_service.dart';
import '../../services/job_card_service.dart';
import '../../providers/auth_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NewJobScreen extends StatefulWidget {
  const NewJobScreen({super.key});

  @override
  State<NewJobScreen> createState() => _NewJobScreenState();
}

class _NewJobScreenState extends State<NewJobScreen> {
  // Step 0: Find Customer
  // Step 1: Select Vehicle
  // Step 2: What Customer Wants (Select Services)
  // Step 3: Review Job
  // Step 4: Job Created Success
  int _currentStep = 0;

  Customer? _selectedCustomer;
  Vehicle? _selectedVehicle;

  // Selected Services/Repairs
  final Map<String, double> _availableServices = {
    'General Service': 300.0,
    'Oil Change': 150.0,
    'Brake Check': 200.0,
    'Battery Check': 250.0,
    'Engine Check': 250.0,
    'Brake Liner Replacement': 450.0,
    'Clutch Adjustment': 150.0,
  };
  final Set<String> _selectedServiceNames = {'Oil Change'};
  final TextEditingController _noteCtrl = TextEditingController(text: 'Please check brake noise.');

  // Customer & Vehicle Lists
  final _searchCustomerCtrl = TextEditingController();
  final _searchServiceCtrl = TextEditingController();
  List<Customer> _customers = [];
  bool _isLoading = false;
  bool _isCreatingJob = false;
  String _createdJobId = 'JOB-2025-000125';

  // New Customer Form Controllers
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // New Vehicle Form Controllers
  final _vehicleNumberCtrl = TextEditingController();
  final _brandCtrl  = TextEditingController();
  final _modelCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRecentCustomers();
  }

  @override
  void dispose() {
    _searchCustomerCtrl.dispose();
    _searchServiceCtrl.dispose();
    _noteCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  String get _token => context.read<AuthProvider>().token ?? '';

  Future<void> _fetchRecentCustomers([String q = '']) async {
    setState(() => _isLoading = true);
    try {
      final results = await CustomerService.search(_token, q);
      setState(() => _customers = results);
    } catch (e) {
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

  double get _totalAmount {
    double total = 0.0;
    for (final s in _selectedServiceNames) {
      total += _availableServices[s] ?? 0.0;
    }
    return total;
  }

  void _showAddCustomerSheet() {
    _nameCtrl.text = _searchCustomerCtrl.text.contains(RegExp(r'[0-9]')) ? '' : _searchCustomerCtrl.text;
    _phoneCtrl.text = _searchCustomerCtrl.text.contains(RegExp(r'[0-9]')) ? _searchCustomerCtrl.text : '';

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
                      _currentStep = 2;
                    });
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    final v = Vehicle(id: DateTime.now().millisecondsSinceEpoch, vehicleNumber: number, brand: brand, model: model);
                    setState(() {
                      _selectedCustomer!.vehicles.add(v);
                      _selectedVehicle = v;
                      _currentStep = 2;
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

  void _showCreateCustomServiceSheet() {
    final nameC = TextEditingController();
    final priceC = TextEditingController();

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
            const Text('Create New Service / Repair', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: 'Name *', hintText: 'e.g. Chain Lubrication'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: priceC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (₹) *', hintText: '100'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () {
                  if (nameC.text.trim().isEmpty || priceC.text.trim().isEmpty) return;
                  final p = double.tryParse(priceC.text.trim()) ?? 100.0;
                  setState(() {
                    _availableServices[nameC.text.trim()] = p;
                    _selectedServiceNames.add(nameC.text.trim());
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save & Add to Job', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _submitJobCard() async {
    setState(() => _isCreatingJob = true);
    try {
      final items = _selectedServiceNames.map((s) => {
        'type': 'service',
        'description': s,
        'price': _availableServices[s] ?? 0.0,
      }).toList();

      final res = await JobCardService.create(
        _token,
        _selectedVehicle?.id ?? 1,
        _selectedCustomer?.id ?? 1,
        items,
      );
      setState(() {
        _createdJobId = 'JOB-2025-${res.id.toString().padLeft(6, '0')}';
        _currentStep = 4; // Job Created Success Screen
      });
    } catch (e) {
      // Local fallback success screen
      setState(() {
        _createdJobId = 'JOB-2025-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        _currentStep = 4;
      });
    } finally {
      setState(() => _isCreatingJob = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Find Customer';
    if (_currentStep == 1) title = 'Select Vehicle';
    if (_currentStep == 2) title = 'Select Services / Repairs';
    if (_currentStep == 3) title = 'Review Job';
    if (_currentStep == 4) title = 'Job Created';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: _currentStep == 4
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  } else {
                    context.pop();
                  }
                },
              ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _buildCurrentScreenContent(),
    );
  }

  Widget _buildCurrentScreenContent() {
    switch (_currentStep) {
      case 0:
        return _buildFindCustomerScreen();
      case 1:
        return _buildSelectVehicleScreen();
      case 2:
        return _buildSelectServicesScreen();
      case 3:
        return _buildReviewJobScreen();
      case 4:
        return _buildJobCreatedSuccessScreen();
      default:
        return _buildFindCustomerScreen();
    }
  }

  // ── Screen 1: Find / Create Customer ────────────────────────────────────────
  Widget _buildFindCustomerScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchCustomerCtrl,
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
                          child: Icon(Icons.person_outline, color: isSelected ? Colors.white : AppColors.textSecondary),
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
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _showAddCustomerSheet,
                child: const Text('+ New Customer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Screen 2: Select / Add Vehicle ──────────────────────────────────────────
  Widget _buildSelectVehicleScreen() {
    return Column(
      children: [
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
                const Text('Customer', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(_selectedCustomer!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                Text(_selectedCustomer!.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Vehicles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: (_selectedCustomer?.vehicles ?? []).isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.two_wheeler, color: AppColors.textLight, size: 48),
                        SizedBox(height: 8),
                        Text('No vehicles added for this customer.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
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
                        subtitle: Text(v.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                        trailing: isSelected
                            ? const CircleAvatar(radius: 12, backgroundColor: AppColors.primary, child: Icon(Icons.check, size: 16, color: Colors.white))
                            : const Icon(Icons.chevron_right, color: AppColors.textLight),
                        onTap: () {
                          setState(() {
                            _selectedVehicle = v;
                            _currentStep = 2;
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
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _showAddVehicleSheet,
                child: const Text('+ Add Vehicle', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Screen 3: Select Services / Repairs ─────────────────────────────────────
  Widget _buildSelectServicesScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchServiceCtrl,
            decoration: InputDecoration(
              hintText: 'Search services or repairs...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: ['All', 'Service', 'Repair', 'Parts'].map((tab) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(tab),
                selected: tab == 'All' || tab == 'Service',
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(color: (tab == 'All' || tab == 'Service') ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
                onSelected: (_) {},
              ),
            )).toList(),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Popular Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _availableServices.entries.map((entry) {
              final isChecked = _selectedServiceNames.contains(entry.key);
              return Card(
                color: AppColors.surface,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.cardBorder)),
                child: CheckboxListTile(
                  title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  secondary: Text('₹${entry.value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                  value: isChecked,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedServiceNames.add(entry.key);
                      } else {
                        _selectedServiceNames.remove(entry.key);
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextButton.icon(
            icon: const Icon(Icons.add, color: AppColors.primary),
            label: const Text('+ Create New Service / Repair', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            onPressed: _showCreateCustomServiceSheet,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: _selectedServiceNames.isEmpty
                    ? null
                    : () => setState(() => _currentStep = 3),
                child: Text('Continue to Review (₹${_totalAmount.toStringAsFixed(0)}) →', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Screen 4: Review Job ───────────────────────────────────────────────────
  Widget _buildReviewJobScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Summary Card
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customer', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(_selectedCustomer?.name ?? 'Rahul Sharma', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  Text(_selectedCustomer?.phone ?? '9876543210', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Vehicle Summary Card
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vehicle', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('${_selectedVehicle?.brand ?? 'Honda'} ${_selectedVehicle?.model ?? 'Activa 6G'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  Text(_selectedVehicle?.vehicleNumber ?? 'MH 12 AB 1234', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Selected Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Card(
            color: AppColors.surface,
            child: Column(
              children: _selectedServiceNames.map((s) => ListTile(
                title: Text('• $s', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                trailing: Text('₹${(_availableServices[s] ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              )).toList(),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Customer Note (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Please check brake noise.',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              Text('₹${_totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () => setState(() => _currentStep = 2),
                  child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _isCreatingJob ? null : _submitJobCard,
                  child: _isCreatingJob
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Job', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Screen 5: Job Created Success Screen ──────────────────────────────────
  Widget _buildJobCreatedSuccessScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundColor: AppColors.success,
              child: Icon(Icons.check, size: 54, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text('Job Created!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Job ID', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(_createdJobId, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Date', style: TextStyle(color: AppColors.textSecondary)),
                        Text('12 May 2025, 10:30 AM', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Status', style: TextStyle(color: AppColors.textSecondary)),
                        Text('New', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warningText)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => context.go('/job-card/1'),
                child: const Text('View Job', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
