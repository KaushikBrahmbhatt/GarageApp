import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  List<Customer> _customers = [
    Customer(id: 1, name: 'Rahul Sharma', phone: '9876543210', email: 'rahul@gmail.com', vehicles: []),
    Customer(id: 2, name: 'Amit Patel', phone: '9876512340', email: 'amit@gmail.com', vehicles: []),
    Customer(id: 3, name: 'Vijay Joshi', phone: '9812545678', email: 'vijay@gmail.com', vehicles: []),
    Customer(id: 4, name: 'Suresh Kumar', phone: '9821122334', email: 'suresh@gmail.com', vehicles: []),
    Customer(id: 5, name: 'Pooja Singh', phone: '9765432190', email: 'pooja@gmail.com', vehicles: []),
  ];

  String get _token => context.read<AuthProvider>().token ?? '';

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
            ),
          ),
          Expanded(
            child: ListView.builder(
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
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
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
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
  }
}
