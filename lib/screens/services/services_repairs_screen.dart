import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class ServicesRepairsScreen extends StatefulWidget {
  const ServicesRepairsScreen({super.key});

  @override
  State<ServicesRepairsScreen> createState() => _ServicesRepairsScreenState();
}

class _ServicesRepairsScreenState extends State<ServicesRepairsScreen> {
  String _selectedTab = 'All';

  final List<Map<String, dynamic>> _items = [
    {'name': 'General Service', 'price': 300, 'type': 'Service'},
    {'name': 'Oil Change', 'price': 150, 'type': 'Service'},
    {'name': 'Brake Check', 'price': 200, 'type': 'Service'},
    {'name': 'Battery Check', 'price': 250, 'type': 'Service'},
    {'name': 'Engine Check', 'price': 250, 'type': 'Service'},
    {'name': 'Brake Liner Replacement', 'price': 450, 'type': 'Repair'},
    {'name': 'Clutch Adjustment', 'price': 150, 'type': 'Repair'},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedTab == 'All'
        ? _items
        : _items.where((i) => i['type'] == _selectedTab).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Services & Repairs', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search services or repairs',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: ['All', 'Service', 'Repair'].map((tab) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(tab),
                      selected: _selectedTab == tab,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: _selectedTab == tab ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
                      onSelected: (_) => setState(() => _selectedTab = tab),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    trailing: Text('₹${item['price']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
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
              label: const Text('+ Add Service', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
