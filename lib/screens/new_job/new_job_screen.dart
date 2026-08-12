import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
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
  int _currentStep = 0;
  Customer? _selectedCustomer;
  Vehicle? _selectedVehicle;
  final List<Map<String, dynamic>> _items = [];
  bool _isSaving = false;

  // Step 1 – Customer search
  final _searchCtrl = TextEditingController();
  List<Customer> _searchResults = [];
  bool _isSearching = false;

  // New customer form
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // New vehicle form
  final _vehicleNumberCtrl = TextEditingController();
  final _brandCtrl  = TextEditingController();
  final _modelCtrl  = TextEditingController();
  final _colorCtrl  = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose();
    _vehicleNumberCtrl.dispose(); _brandCtrl.dispose();
    _modelCtrl.dispose(); _colorCtrl.dispose();
    super.dispose();
  }

  String get _token => context.read<AuthProvider>().token ?? '';

  Future<void> _searchCustomers(String q) async {
    if (q.length < 3) { setState(() => _searchResults = []); return; }
    setState(() => _isSearching = true);
    try {
      final results = await CustomerService.search(_token, q);
      setState(() => _searchResults = results);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _applyPresetPackage(String type) {
    setState(() {
      _items.clear();
      if (type == 'general_service') {
        _items.addAll([
          {'type': 'oil', 'description': 'Engine Oil Change', 'price': 350.0, 'flag': 'none'},
          {'type': 'service', 'description': 'Brake Pad Check & Adjustment', 'price': 150.0, 'flag': 'none'},
          {'type': 'service', 'description': 'Chain Lubrication & Tensioning', 'price': 100.0, 'flag': 'none'},
          {'type': 'service', 'description': 'Air Filter Cleaning', 'price': 200.0, 'flag': 'none'},
        ]);
      } else if (type == 'repair_work') {
        _items.addAll([
          {'type': 'repair', 'description': 'Spark Plug Replacement', 'price': 250.0, 'flag': 'needs_inspection'},
          {'type': 'repair', 'description': 'Battery & Electrical Health Check', 'price': 120.0, 'flag': 'none'},
          {'type': 'repair', 'description': 'Wheel Balancing & Alignment', 'price': 400.0, 'flag': 'none'},
        ]);
      }
    });
    Fluttertoast.showToast(msg: 'Applied $type package!');
  }

  void _showAddCustomerSheet() {
    _nameCtrl.text = _searchCtrl.text.contains(RegExp(r'[0-9]')) ? '' : _searchCtrl.text;
    _phoneCtrl.text = _searchCtrl.text.contains(RegExp(r'[0-9]')) ? _searchCtrl.text : '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddCustomerSheet(
        nameCtrl: _nameCtrl, phoneCtrl: _phoneCtrl, emailCtrl: _emailCtrl,
        onSave: () async {
          try {
            final c = await CustomerService.create(_token, _nameCtrl.text, _phoneCtrl.text, _emailCtrl.text);
            setState(() { _selectedCustomer = c; _searchResults = []; });
            if (mounted) { Navigator.pop(context); setState(() => _currentStep = 1); }
          } catch (e) {
            Fluttertoast.showToast(msg: 'Error: $e');
          }
        },
      ),
    );
  }

  void _showAddVehicleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddVehicleSheet(
        numberCtrl: _vehicleNumberCtrl, brandCtrl: _brandCtrl,
        modelCtrl: _modelCtrl, colorCtrl: _colorCtrl,
        onSave: () async {
          try {
            final v = await VehicleService.create(
              _token, _selectedCustomer!.id,
              _vehicleNumberCtrl.text, _brandCtrl.text,
              _modelCtrl.text, _colorCtrl.text,
            );
            setState(() => _selectedVehicle = v);
            if (mounted) { Navigator.pop(context); setState(() => _currentStep = 2); }
          } catch (e) {
            Fluttertoast.showToast(msg: 'Error: $e');
          }
        },
      ),
    );
  }

  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddItemSheet(
        onAdd: (item) => setState(() => _items.add(item)),
      ),
    );
  }

  Future<void> _saveJobCard() async {
    if (_selectedVehicle == null || _selectedCustomer == null) return;
    setState(() => _isSaving = true);
    try {
      final jobCard = await JobCardService.create(
        _token, _selectedVehicle!.id, _selectedCustomer!.id, _items,
      );
      if (mounted) {
        Fluttertoast.showToast(msg: 'Job card created!');
        context.go('/job-card/${jobCard.id}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  double get _totalEstimate => _items.fold(0.0, (sum, i) => sum + ((i['price'] as num).toDouble()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: const Text('Create New Job'),
        backgroundColor: AppTheme.kSurface,
      ),
      body: Stepper(
        currentStep: _currentStep,
        connectorColor: WidgetStateProperty.all(AppTheme.kPrimary),
        onStepTapped: (s) { if (s < _currentStep) setState(() => _currentStep = s); },
        onStepContinue: () {
          if (_currentStep == 0 && _selectedCustomer != null) setState(() => _currentStep = 1);
          if (_currentStep == 1 && _selectedVehicle != null) setState(() => _currentStep = 2);
        },
        onStepCancel: () { if (_currentStep > 0) setState(() => _currentStep--); },
        controlsBuilder: (ctx, details) {
          if (_currentStep == 2) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                if (details.onStepContinue != null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kPrimary),
                    onPressed: details.onStepContinue,
                    child: const Text('Continue', style: TextStyle(color: Colors.white)),
                  ),
                const SizedBox(width: 8),
                if (_currentStep > 0)
                  TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
              ],
            ),
          );
        },
        steps: [
          // ── Step 1: Customer ──────────────────────────────────────
          Step(
            title: Text('Customer', style: TextStyle(color: _currentStep >= 0 ? AppTheme.kPrimary : AppTheme.kTextMuted, fontWeight: FontWeight.bold)),
            subtitle: _selectedCustomer != null ? Text(_selectedCustomer!.name) : null,
            isActive: _currentStep >= 0,
            state: _selectedCustomer != null ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: AppTheme.kTextPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone...',
                    hintStyle: const TextStyle(color: AppTheme.kTextMuted),
                    prefixIcon: _isSearching
                        ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                        : const Icon(Icons.search, color: AppTheme.kTextMuted),
                  ),
                  onChanged: _searchCustomers,
                ),
                ..._searchResults.map((c) => ListTile(
                  leading: const CircleAvatar(backgroundColor: AppTheme.kPrimary, child: Icon(Icons.person, color: Colors.white)),
                  title: Text(c.name, style: const TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text(c.phone, style: const TextStyle(color: AppTheme.kTextMuted)),
                  trailing: Text('${c.vehicles.length} vehicle(s)', style: const TextStyle(color: AppTheme.kTextMuted, fontSize: 12)),
                  onTap: () => setState(() { _selectedCustomer = c; _searchResults = []; _currentStep = 1; }),
                )),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_add, color: AppTheme.kPrimary),
                    label: const Text('Add New Customer', style: TextStyle(color: AppTheme.kPrimary, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.kPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _showAddCustomerSheet,
                  ),
                ),
              ],
            ),
          ),

          // ── Step 2: Vehicle ───────────────────────────────────────
          Step(
            title: Text('Vehicle', style: TextStyle(color: _currentStep >= 1 ? AppTheme.kPrimary : AppTheme.kTextMuted, fontWeight: FontWeight.bold)),
            subtitle: _selectedVehicle != null ? Text(_selectedVehicle!.vehicleNumber) : null,
            isActive: _currentStep >= 1,
            state: _selectedVehicle != null ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                if (_selectedCustomer != null)
                  ..._selectedCustomer!.vehicles.map((v) => Card(
                    color: _selectedVehicle?.id == v.id ? AppTheme.kPrimary.withValues(alpha: 0.1) : AppTheme.kSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: _selectedVehicle?.id == v.id ? AppTheme.kPrimary : AppTheme.kBorder, width: _selectedVehicle?.id == v.id ? 2 : 1),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.two_wheeler, color: AppTheme.kPrimary, size: 28),
                      title: Text(v.vehicleNumber, style: const TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold)),
                      subtitle: Text('${v.brand ?? ''} ${v.model ?? ''}'.trim(), style: const TextStyle(color: AppTheme.kTextMuted)),
                      onTap: () => setState(() { _selectedVehicle = v; _currentStep = 2; }),
                    ),
                  )),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, color: AppTheme.kPrimary),
                    label: const Text('Add New Vehicle', style: TextStyle(color: AppTheme.kPrimary, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.kPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _showAddVehicleSheet,
                  ),
                ),
              ],
            ),
          ),

          // ── Step 3: Preset Shortcuts & Items ──────────────────────
          Step(
            title: Text('Select Job Type & Items', style: TextStyle(color: _currentStep >= 2 ? AppTheme.kPrimary : AppTheme.kTextMuted, fontWeight: FontWeight.bold)),
            isActive: _currentStep >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3 Big Shortcut Buttons
                const Text('Quick Select Job Type:', style: TextStyle(color: AppTheme.kTextMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ShortcutCard(
                        icon: Icons.build_circle,
                        title: 'General Service',
                        color: AppTheme.kAccent,
                        onTap: () => _applyPresetPackage('general_service'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ShortcutCard(
                        icon: Icons.handyman,
                        title: 'Repair Work',
                        color: AppTheme.kPrimary,
                        onTap: () => _applyPresetPackage('repair_work'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ShortcutCard(
                        icon: Icons.settings,
                        title: 'Custom Job',
                        color: AppTheme.kSuccess,
                        onTap: _showAddItemSheet,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Job Checklist:', style: TextStyle(color: AppTheme.kTextMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_items.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.kSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.kBorder),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.checklist_rtl, color: AppTheme.kTextMuted, size: 36),
                        SizedBox(height: 8),
                        Text('Tap a Quick Select button above or add custom items.', style: TextStyle(color: AppTheme.kTextMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                ..._items.asMap().entries.map((e) => _ItemRow(
                  item: e.value,
                  onDelete: () => setState(() => _items.removeAt(e.key)),
                )),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add, color: AppTheme.kPrimary),
                  label: const Text('Add Custom Item', style: TextStyle(color: AppTheme.kPrimary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.kPrimary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _showAddItemSheet,
                ),
                if (_items.isNotEmpty) ...[
                  const Divider(height: 24, color: AppTheme.kBorder),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Estimated Amount', style: TextStyle(color: AppTheme.kTextMuted, fontSize: 15, fontWeight: FontWeight.w600)),
                      Text('₹${_totalEstimate.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppTheme.kPrimary, fontWeight: FontWeight.bold, fontSize: 22)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.kAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isSaving ? null : _saveJobCard,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save & Create Job Card', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shortcut Card ────────────────────────────────────────────────────────────
class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ShortcutCard({required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add Customer Sheet ──────────────────────────────────────────────────────
class _AddCustomerSheet extends StatelessWidget {
  final TextEditingController nameCtrl, phoneCtrl, emailCtrl;
  final VoidCallback onSave;
  const _AddCustomerSheet({required this.nameCtrl, required this.phoneCtrl, required this.emailCtrl, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('New Customer', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildField(nameCtrl, 'Name *'),
        const SizedBox(height: 12),
        _buildField(phoneCtrl, 'Phone *', keyboard: TextInputType.phone),
        const SizedBox(height: 12),
        _buildField(emailCtrl, 'Email (optional)', keyboard: TextInputType.emailAddress),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: onSave,
            child: const Text('Save Customer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: AppTheme.kTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.kTextMuted),
      ),
    );
  }
}

// ── Add Vehicle Sheet ───────────────────────────────────────────────────────
class _AddVehicleSheet extends StatelessWidget {
  final TextEditingController numberCtrl, brandCtrl, modelCtrl, colorCtrl;
  final VoidCallback onSave;
  const _AddVehicleSheet({required this.numberCtrl, required this.brandCtrl, required this.modelCtrl, required this.colorCtrl, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('New Vehicle', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildField(numberCtrl, 'Vehicle Number *'),
        const SizedBox(height: 12),
        _buildField(brandCtrl, 'Brand (e.g. Honda)'),
        const SizedBox(height: 12),
        _buildField(modelCtrl, 'Model (e.g. Activa)'),
        const SizedBox(height: 12),
        _buildField(colorCtrl, 'Color'),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: onSave,
            child: const Text('Save Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: AppTheme.kTextPrimary),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: AppTheme.kTextMuted),
      ),
    );
  }
}

// ── Add Item Sheet ──────────────────────────────────────────────────────────
class _AddItemSheet extends StatefulWidget {
  final void Function(Map<String, dynamic>) onAdd;
  const _AddItemSheet({required this.onAdd});
  @override State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  String _type = 'repair';
  String _flag = 'none';
  final _descCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Add Custom Job Item', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.kTextPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text('Type', style: TextStyle(color: AppTheme.kTextMuted, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: ['repair', 'service', 'oil', 'part', 'other'].map((t) => ChoiceChip(
          label: Text(t[0].toUpperCase() + t.substring(1)),
          selected: _type == t,
          selectedColor: AppTheme.kPrimary,
          onSelected: (_) => setState(() => _type = t),
        )).toList()),
        const SizedBox(height: 12),
        TextField(
          controller: _descCtrl,
          style: const TextStyle(color: AppTheme.kTextPrimary),
          decoration: const InputDecoration(labelText: 'Description *'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _priceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppTheme.kTextPrimary),
          decoration: const InputDecoration(
            labelText: 'Price (₹) *',
            prefixText: '₹ ', prefixStyle: TextStyle(color: AppTheme.kPrimary, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Status Flag', style: TextStyle(color: AppTheme.kTextMuted, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          _flagChip('none', 'None', Colors.grey),
          _flagChip('needs_inspection', '🟡 Needs Inspection', AppTheme.kWarning),
          _flagChip('needs_confirmation', '🔵 Needs Confirmation', AppTheme.kPrimary),
        ]),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: () {
              if (_descCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) return;
              widget.onAdd({'type': _type, 'description': _descCtrl.text.trim(), 'price': double.tryParse(_priceCtrl.text) ?? 0, 'flag': _flag});
              Navigator.pop(context);
            },
            child: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _flagChip(String value, String label, Color color) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: _flag == value ? Colors.white : color, fontSize: 12)),
      selected: _flag == value,
      selectedColor: color.withValues(alpha: 0.8),
      onSelected: (_) => setState(() => _flag = value),
    );
  }
}

// ── Item Row widget ─────────────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;
  const _ItemRow({required this.item, required this.onDelete});

  Color get _flagColor {
    switch (item['flag']) {
      case 'needs_inspection': return AppTheme.kWarning;
      case 'needs_confirmation': return AppTheme.kPrimary;
      case 'confirmed': return AppTheme.kSuccess;
      default: return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.kSurface,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: AppTheme.kPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(item['type'].toString().toUpperCase(), style: const TextStyle(color: AppTheme.kPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        title: Text(item['description'], style: const TextStyle(color: AppTheme.kTextPrimary, fontWeight: FontWeight.w600)),
        subtitle: item['flag'] != 'none'
            ? Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: _flagColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(item['flag'].toString().replaceAll('_', ' '), style: TextStyle(color: _flagColor, fontSize: 11, fontWeight: FontWeight.bold)),
              )
            : null,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('₹${((item['price'] as num).toDouble()).toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.kPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.kError, size: 20), onPressed: onDelete),
        ]),
      ),
    );
  }
}
