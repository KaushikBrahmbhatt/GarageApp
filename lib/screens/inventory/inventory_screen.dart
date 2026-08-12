import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final List<Map<String, dynamic>> _parts = [
    {'name': 'Engine Oil (10W30)', 'price': 450, 'stock': 10},
    {'name': 'Brake Liner', 'price': 450, 'stock': 8},
    {'name': 'Air Filter', 'price': 120, 'stock': 15},
    {'name': 'Spark Plug', 'price': 90, 'stock': 20},
    {'name': 'Chain Set', 'price': 550, 'stock': 5},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Parts / Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search parts',
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
              itemCount: _parts.length,
              itemBuilder: (context, index) {
                final part = _parts[index];
                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.inventory_2, color: AppColors.primary),
                    ),
                    title: Text(part['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    subtitle: Text('Stock: ${part['stock']}', style: const TextStyle(color: AppColors.textSecondary)),
                    trailing: Text('₹${part['price']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
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
              label: const Text('+ Add Part', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
