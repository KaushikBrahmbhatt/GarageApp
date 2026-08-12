import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  List<Customer> _customers = [];
  bool _isLoading = false;
  bool _isSaving = false;

  // New customer form
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String get _token => context.read<AuthProvider>().token ?? '';

  Future<void> _fetchCustomers([String q = '']) async {
    setState(() => _isLoading = true);
    try {
      final results = await CustomerService.search(_token, q);
      setState(() => _customers = results);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error loading customers');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddCustomerSheet() {
    _nameCtrl.clear();
    _phoneCtrl.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 24),
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
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
                            Fluttertoast.showToast(msg: 'Name and Phone Number are required');
                            return;
                          }
                          setSheetState(() => _isSaving = true);
                          try {
                            await CustomerService.create(_token, _nameCtrl.text.trim(), _phoneCtrl.text.trim(), '');
                            if (mounted) {
                              Navigator.pop(ctx);
                              _fetchCustomers();
                              Fluttertoast.showToast(msg: 'Customer saved successfully!');
                            }
                          } catch (e) {
                            Fluttertoast.showToast(msg: 'Error: $e');
                          } finally {
                            setSheetState(() => _isSaving = false);
                          }
                        },
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Customer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customers', style: TextStyle(fontWeight: FontWeight.bold)),
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
                hintText: 'Search by name or mobile',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
              ),
              onChanged: (q) => _fetchCustomers(q),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.people_outline, color: AppColors.textLight, size: 48),
                            SizedBox(height: 12),
                            Text('No customers found.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _customers.length,
                        itemBuilder: (context, index) {
                          final c = _customers[index];
                          return Card(
                            color: AppColors.surface,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Icon(Icons.person, color: AppColors.primary),
                              ),
                              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              subtitle: Text(c.phone, style: const TextStyle(color: AppColors.textSecondary)),
                              trailing: Text('${c.vehicles.length} vehicle(s)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('+ Add Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _showAddCustomerSheet,
            ),
          ),
        ),
      ),
    );
  }
}
